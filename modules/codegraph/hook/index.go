package main

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

var spawn = func(roots ...string) {
	if len(roots) == 0 {
		return
	}
	self, err := os.Executable()
	if err != nil {
		return
	}
	cmd := exec.Command(self, append([]string{"refresh"}, roots...)...)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	if cmd.Start() == nil {
		_ = cmd.Process.Release()
	}
}

func dbPath(root string) string {
	return filepath.Join(root, ".codegraph", "codegraph.db")
}

func indexed(root string) bool {
	return exists(dbPath(root))
}

// Sync is incremental and ~100ms, which is why the bundled daemon stays off.
// A missing index is built detached so a large repo does not stall the
// session.
func ensure(root string) {
	if !indexed(root) || !refresh(root, true) {
		spawn(root)
	}
}

func refresh(root string, foreground bool) (settled bool) {
	gitDir, err := git(root, "rev-parse", "--path-format=absolute", "--git-dir")
	if err != nil {
		return true
	}
	return runLocked(
		filepath.Join(gitDir, "codegraph.lock"),
		filepath.Join(gitDir, "codegraph.dirty"),
		foreground,
		func(lock *os.File) error {
			return update(root, filepath.Join(gitDir, "codegraph.state"), lock, foreground)
		},
	)
}

func runLocked(lockPath, dirtyPath string, once bool, work func(lock *os.File) error) (settled bool) {
	if os.WriteFile(dirtyPath, nil, 0o644) != nil {
		return true
	}
	for exists(dirtyPath) {
		lock, ok := tryLock(lockPath)
		if !ok {
			return true
		}
		var err error
		if os.Remove(dirtyPath) == nil {
			err = work(lock)
		}
		if err != nil {
			_ = os.WriteFile(dirtyPath, nil, 0o644)
		}
		_ = lock.Close()
		if err != nil || once {
			return !exists(dirtyPath)
		}
	}
	return true
}

func tryLock(path string) (*os.File, bool) {
	return flock(path, syscall.LOCK_EX|syscall.LOCK_NB)
}

func flock(path string, how int) (*os.File, bool) {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return nil, false
	}
	if syscall.Flock(int(f.Fd()), how) != nil {
		_ = f.Close()
		return nil, false
	}
	return f, true
}

func update(root, statePath string, lock *os.File, foreground bool) error {
	if foreground {
		if err := codegraph(root, lock, "sync", "--quiet"); err != nil {
			return err
		}
		_ = os.Remove(statePath)
		return nil
	}
	state := fingerprint(root)
	if indexed(root) {
		if prev, err := os.ReadFile(statePath); state != "" && err == nil && string(prev) == state {
			return nil
		}
		if err := codegraph(root, lock, "sync", "--quiet"); err != nil {
			if codegraph(root, lock, "status") == nil {
				return err
			}
			if err := rebuild(root, lock); err != nil {
				return err
			}
		}
	} else if err := build(root, lock); err != nil {
		return err
	}
	return os.WriteFile(statePath, []byte(state), 0o644)
}

func fingerprint(root string) string {
	status, err := gitRaw(root, "status", "--porcelain=v1", "-z", "--untracked-files=all")
	if err != nil {
		return ""
	}
	head, _ := git(root, "rev-parse", "HEAD")
	h := sha256.New()
	fmt.Fprintln(h, head)
	for entry := range strings.SplitSeq(status, "\x00") {
		fmt.Fprintln(h, entry)
		if len(entry) > 3 {
			if info, err := os.Stat(filepath.Join(root, entry[3:])); err == nil {
				fmt.Fprintln(h, info.Size(), info.ModTime().UnixNano())
			}
		}
	}
	return hex.EncodeToString(h.Sum(nil))
}

// ~600ms on a cold repo of 300 files, so a sibling worktree's index is copied
// and synced where one exists.
func build(root string, lock *os.File) error {
	for _, src := range worktrees(root) {
		if src == root || !indexed(src) {
			continue
		}
		_ = os.RemoveAll(filepath.Join(root, ".codegraph"))
		if seed(src, root) == nil && codegraph(root, lock, "sync", "--quiet") == nil {
			return nil
		}
	}
	return rebuild(root, lock)
}

func rebuild(root string, lock *os.File) error {
	_ = os.RemoveAll(filepath.Join(root, ".codegraph"))
	return codegraph(root, lock, "init", "--yes")
}

func seed(src, dst string) error {
	srcGitDir, err := git(src, "rev-parse", "--path-format=absolute", "--git-dir")
	if err != nil {
		return err
	}
	dstGitDir, err := git(dst, "rev-parse", "--path-format=absolute", "--git-dir")
	if err != nil {
		return err
	}
	lock, ok := flock(filepath.Join(srcGitDir, "codegraph.lock"), syscall.LOCK_EX)
	if !ok {
		return errors.New("could not lock source index")
	}
	defer func() {
		_ = lock.Close()
		if exists(filepath.Join(srcGitDir, "codegraph.dirty")) {
			spawn(src)
		}
	}()

	tmp, err := os.MkdirTemp(dstGitDir, "codegraph-seed-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(tmp)
	for _, name := range []string{"codegraph.db", "codegraph.db-wal", ".gitignore"} {
		from := filepath.Join(src, ".codegraph", name)
		if name != "codegraph.db" && !exists(from) {
			continue
		}
		if err := copyFile(from, filepath.Join(tmp, name)); err != nil {
			return err
		}
	}
	return os.Rename(tmp, filepath.Join(dst, ".codegraph"))
}

func copyFile(from, to string) error {
	in, err := os.Open(from)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(to)
	if err != nil {
		return err
	}
	if _, err := io.Copy(out, in); err != nil {
		_ = out.Close()
		return err
	}
	return out.Close()
}

func codegraph(root string, lock *os.File, args ...string) error {
	cmd := exec.Command(codegraphBin, args...)
	cmd.Dir = root
	if lock != nil {
		cmd.ExtraFiles = []*os.File{lock}
	}
	return cmd.Run()
}
