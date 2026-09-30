package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func TestMain(m *testing.M) {
	os.Setenv("GIT_CONFIG_GLOBAL", os.DevNull)
	os.Setenv("GIT_CONFIG_NOSYSTEM", "1")
	os.Exit(m.Run())
}

func run(t *testing.T, dir, name string, args ...string) string {
	t.Helper()
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(),
		"GIT_AUTHOR_NAME=t", "GIT_AUTHOR_EMAIL=t@t",
		"GIT_COMMITTER_NAME=t", "GIT_COMMITTER_EMAIL=t@t",
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("%s %v: %v\n%s", name, args, err, out)
	}
	return string(out)
}

func write(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func newRepo(t *testing.T) (parent, main, wt string) {
	t.Helper()
	parent, err := filepath.EvalSymlinks(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	main = filepath.Join(parent, "main")
	wt = filepath.Join(parent, "wt")
	write(t, filepath.Join(main, "src", "invoice.ts"),
		"export function computeInvoiceTotal(a: number) { return a }\n"+
			"export function renderInvoiceSummary() { return computeInvoiceTotal(1) }\n")
	run(t, main, gitBin, "init", "-q")
	run(t, main, gitBin, "add", ".")
	run(t, main, gitBin, "commit", "-qm", "init")
	run(t, main, gitBin, "worktree", "add", "-q", wt, "-b", "wt")
	return parent, main, wt
}

func TestRootOf(t *testing.T) {
	parent, main, wt := newRepo(t)
	tests := []struct {
		path, want string
		ok         bool
	}{
		{filepath.Join(main, "src", "invoice.ts"), main, true},
		{filepath.Join(main, "src", "gone", "deleted.ts"), main, true},
		{filepath.Join(wt, "src"), wt, true},
		{parent, "", false},
		{"", "", false},
	}
	for _, tt := range tests {
		got, ok := rootOf(tt.path)
		if got != tt.want || ok != tt.ok {
			t.Errorf("rootOf(%q) = %q, %v; want %q, %v", tt.path, got, ok, tt.want, tt.ok)
		}
	}
}

func TestReflogs(t *testing.T) {
	parent, main, wt := newRepo(t)
	relative := filepath.Join(parent, "relative")
	run(t, main, gitBin, "-c", "worktree.useRelativePaths=true", "worktree", "add", "-q", relative, "-b", "relative")
	for _, root := range []string{main, wt, relative} {
		reflog, err := git(root, "rev-parse", "--path-format=absolute", "--git-path", "logs/HEAD")
		if err != nil {
			t.Fatal(err)
		}
		if got := reflogOf(root); got != reflog {
			t.Errorf("reflogOf(%q) = %q; want %q", root, got, reflog)
		}
	}
}

func TestRoots(t *testing.T) {
	parent, main, wt := newRepo(t)
	write(t, dbPath(wt), "")

	if got := roots(filepath.Join(main, "src")); len(got) != 1 || got[0] != main {
		t.Errorf("roots inside a repo = %v; want [%s]", got, main)
	}
	if got := roots(parent); len(got) != 1 || got[0] != wt {
		t.Errorf("roots of a parent = %v; want only the indexed [%s]", got, wt)
	}
}
