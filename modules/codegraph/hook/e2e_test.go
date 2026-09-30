package main

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"
)

func TestEndToEnd(t *testing.T) {
	real, err := exec.LookPath(codegraphBin)
	if err != nil {
		t.Skip("codegraph not available")
	}
	t.Setenv("HOME", t.TempDir())
	t.Setenv("DO_NOT_TRACK", "1")
	t.Setenv("CODEGRAPH_TELEMETRY", "0")
	t.Setenv("CODEGRAPH_NO_DAEMON", "1")
	spawn = func(roots ...string) {
		for _, root := range roots {
			refresh(root, false)
		}
	}

	shim := filepath.Join(t.TempDir(), "codegraph")
	write(t, shim, "#!/bin/sh\n"+
		"echo \"$1\" >> \"$CG_LOG\"\n"+
		"case \" $CG_FAIL \" in *\" $1 \"*) exit 1 ;; esac\n"+
		"exec \""+real+"\" \"$@\"\n")
	if err := os.Chmod(shim, 0o755); err != nil {
		t.Fatal(err)
	}
	codegraphBin = shim
	defer func() { codegraphBin = real }()
	calls := filepath.Join(t.TempDir(), "calls")
	t.Setenv("CG_LOG", calls)
	t.Setenv("CG_FAIL", "")
	logged := func() []string {
		b, _ := os.ReadFile(calls)
		_ = os.Remove(calls)
		return strings.Fields(string(b))
	}

	parent, main, wt := newRepo(t)

	t.Run("session start builds the index and watches the reflog", func(t *testing.T) {
		out := handle(input{Event: "SessionStart", Cwd: main})
		if !indexed(main) {
			t.Fatal("main not indexed")
		}
		if watch := watchPaths(out); !slices.Equal(watch, []string{reflogOf(main)}) {
			t.Fatalf("watchPaths = %v", watch)
		}
	})

	t.Run("entering a worktree seeds it from a sibling", func(t *testing.T) {
		t.Setenv("CG_FAIL", "init")
		handle(input{Event: "CwdChanged", Cwd: main, NewCwd: filepath.Join(wt, "src")})
		if !indexed(wt) {
			t.Fatal("worktree not seeded")
		}
	})

	t.Run("an unchanged worktree is not synced again", func(t *testing.T) {
		refresh(main, false)
		logged()
		refresh(main, false)
		if got := logged(); len(got) != 0 {
			t.Fatalf("codegraph called: %v", got)
		}
	})

	t.Run("an unreadable index is rebuilt", func(t *testing.T) {
		write(t, filepath.Join(main, "src", "rebuilt.ts"), "export function afterRebuild() { return 1 }\n")
		t.Setenv("CG_FAIL", "sync status")
		logged()
		refresh(main, false)
		if got := logged(); !slices.Equal(got, []string{"sync", "status", "init"}) {
			t.Fatalf("codegraph called: %v", got)
		}
		t.Setenv("CG_FAIL", "")
		assertIndexed(t, main, "afterRebuild")
	})

	t.Run("seeding waits for a busy sibling and hands back its queued work", func(t *testing.T) {
		wt2 := filepath.Join(parent, "wt2")
		run(t, main, gitBin, "worktree", "add", "-q", wt2, "-b", "wt2")
		defer run(t, main, gitBin, "worktree", "remove", "--force", wt2)
		t.Setenv("CG_FAIL", "init")

		gitDir, _ := git(main, "rev-parse", "--path-format=absolute", "--git-dir")
		held, ok := tryLock(filepath.Join(gitDir, "codegraph.lock"))
		if !ok {
			t.Fatal("could not take main's lock")
		}
		write(t, filepath.Join(main, "src", "queued.ts"), "export function queuedWhileSeeding() { return 1 }\n")
		write(t, filepath.Join(gitDir, "codegraph.dirty"), "")
		go func() {
			time.Sleep(300 * time.Millisecond)
			_ = held.Close()
		}()

		refresh(wt2, false)
		if !indexed(wt2) {
			t.Fatal("wt2 not seeded")
		}
		assertIndexed(t, main, "queuedWhileSeeding")
	})

	t.Run("a non-repo parent watches every indexed worktree", func(t *testing.T) {
		out := handle(input{Event: "CwdChanged", Cwd: wt, NewCwd: parent})
		watch := watchPaths(out)
		slices.Sort(watch)
		want := []string{reflogOf(main), reflogOf(wt)}
		slices.Sort(want)
		if !slices.Equal(watch, want) {
			t.Fatalf("watchPaths = %v; want %v", watch, want)
		}
	})

	t.Run("shell changes are synced", func(t *testing.T) {
		write(t, filepath.Join(wt, "src", "shell.ts"), "export function writtenByShell() { return 1 }\n")
		handle(input{Event: "PostToolUse", ToolName: "Bash", Cwd: wt, ToolInput: json.RawMessage(`{"command":"x"}`)})
		assertIndexed(t, wt, "writtenByShell")
	})

	t.Run("shell changes from a non-repo parent are synced", func(t *testing.T) {
		write(t, filepath.Join(wt, "src", "parent.ts"), "export function writtenFromParent() { return 1 }\n")
		handle(input{Event: "PostToolUse", ToolName: "Bash", Cwd: parent, ToolInput: json.RawMessage(`{"command":"x"}`)})
		assertIndexed(t, wt, "writtenFromParent")
	})

	t.Run("edits sync the file's worktree, not the session's", func(t *testing.T) {
		path := filepath.Join(wt, "src", "edited.ts")
		write(t, path, "export function editedInWorktree() { return 1 }\n")
		raw, _ := json.Marshal(map[string]string{"file_path": path})
		handle(input{Event: "PostToolUse", ToolName: "Edit", Cwd: parent, ToolInput: raw})
		assertIndexed(t, wt, "editedInWorktree")
	})

	t.Run("reflog changes are synced and the watch set is kept", func(t *testing.T) {
		run(t, wt, gitBin, "add", ".")
		run(t, wt, gitBin, "commit", "-qm", "move")
		run(t, wt, gitBin, "rm", "-q", "src/shell.ts")
		run(t, wt, gitBin, "commit", "-qm", "drop")
		out := handle(input{Event: "FileChanged", Cwd: main, FilePath: reflogOf(wt)})
		assertNotIndexed(t, wt, "writtenByShell")
		if watch := watchPaths(out); len(watch) != 2 {
			t.Fatalf("watchPaths = %v", watch)
		}
	})

	const prompt = "--how does computeInvoiceTotal feed renderInvoiceSummary"

	t.Run("prompts get locators", func(t *testing.T) {
		out := handle(input{Event: "UserPromptSubmit", Cwd: main, Prompt: prompt})
		if out == nil {
			t.Fatal("no output")
		}
		ctx, _ := out.HookSpecificOutput["additionalContext"].(string)
		if !strings.Contains(ctx, "computeInvoiceTotal — src/invoice.ts:1") {
			t.Fatalf("additionalContext = %q", ctx)
		}
	})

	t.Run("subagent prompts get locators, other input is kept", func(t *testing.T) {
		raw, _ := json.Marshal(map[string]string{"description": "d", "subagent_type": "Explore", "prompt": prompt})
		out := handle(input{Event: "PreToolUse", ToolName: "Agent", Cwd: main, ToolInput: raw})
		if out == nil {
			t.Fatal("no output")
		}
		updated, _ := out.HookSpecificOutput["updatedInput"].(map[string]any)
		got, _ := updated["prompt"].(string)
		if updated["subagent_type"] != "Explore" || !strings.HasPrefix(got, prompt+"\n\n"+header) {
			t.Fatalf("updatedInput = %v", updated)
		}
	})

	t.Run("other tools are left alone", func(t *testing.T) {
		raw, _ := json.Marshal(map[string]string{"prompt": prompt})
		if out := handle(input{Event: "PreToolUse", ToolName: "Bash", Cwd: main, ToolInput: raw}); out != nil {
			t.Fatalf("unexpected output %v", out)
		}
	})
}

func watchPaths(out *output) []string {
	if out == nil {
		return nil
	}
	paths, _ := out.HookSpecificOutput["watchPaths"].([]string)
	return slices.Clone(paths)
}

func query(t *testing.T, root, symbol string) string {
	t.Helper()
	cmd := exec.Command(codegraphBin, "query", "--json", "--", symbol)
	cmd.Dir = root
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("query %s in %s: %v", symbol, root, err)
	}
	return string(out)
}

func assertIndexed(t *testing.T, root, symbol string) {
	t.Helper()
	if out := query(t, root, symbol); !strings.Contains(out, `"name": "`+symbol+`"`) {
		t.Fatalf("%s not indexed in %s:\n%s", symbol, root, out)
	}
}

func assertNotIndexed(t *testing.T, root, symbol string) {
	t.Helper()
	if out := query(t, root, symbol); strings.Contains(out, `"name": "`+symbol+`"`) {
		t.Fatalf("%s still indexed in %s", symbol, root)
	}
}
