package main

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
)

func TestRunLockedSkipsWhileHeld(t *testing.T) {
	dir := t.TempDir()
	lockPath, dirtyPath := filepath.Join(dir, "lock"), filepath.Join(dir, "dirty")

	held, ok := tryLock(lockPath)
	if !ok {
		t.Fatal("could not take lock")
	}
	defer held.Close()

	runLocked(lockPath, dirtyPath, false, func(*os.File) error {
		t.Fatal("ran while locked")
		return nil
	})
	if !exists(dirtyPath) {
		t.Fatal("request was not left for the holder")
	}
}

func TestRunLockedHolderPicksUpLateRequests(t *testing.T) {
	dir := t.TempDir()
	lockPath, dirtyPath := filepath.Join(dir, "lock"), filepath.Join(dir, "dirty")

	calls := 0
	runLocked(lockPath, dirtyPath, false, func(*os.File) error {
		calls++
		if calls == 1 {
			runLocked(lockPath, dirtyPath, false, func(*os.File) error {
				t.Fatal("ran while locked")
				return nil
			})
		}
		return nil
	})
	if calls != 2 {
		t.Fatalf("want 2 runs, got %d", calls)
	}
	if exists(dirtyPath) {
		t.Fatal("dirty marker left behind")
	}
}

func TestRunLockedOnceLeavesLateRequestsPending(t *testing.T) {
	dir := t.TempDir()
	lockPath, dirtyPath := filepath.Join(dir, "lock"), filepath.Join(dir, "dirty")

	calls := 0
	done := runLocked(lockPath, dirtyPath, true, func(*os.File) error {
		calls++
		runLocked(lockPath, dirtyPath, true, func(*os.File) error {
			t.Fatal("ran while locked")
			return nil
		})
		return nil
	})
	if calls != 1 || done || !exists(dirtyPath) {
		t.Fatalf("calls = %d, done = %v, dirty = %v; want 1, false, true", calls, done, exists(dirtyPath))
	}
}

func TestRunLockedKeepsFailedRequests(t *testing.T) {
	dir := t.TempDir()
	lockPath, dirtyPath := filepath.Join(dir, "lock"), filepath.Join(dir, "dirty")

	calls := 0
	runLocked(lockPath, dirtyPath, false, func(*os.File) error {
		calls++
		return errors.New("busy")
	})
	if calls != 1 {
		t.Fatalf("want 1 run, got %d", calls)
	}
	if !exists(dirtyPath) {
		t.Fatal("failed request was dropped")
	}
}

func TestFingerprint(t *testing.T) {
	_, main, _ := newRepo(t)
	path := filepath.Join(main, "src", "invoice.ts")

	clean := fingerprint(main)
	if clean == "" || fingerprint(main) != clean {
		t.Fatal("fingerprint is not stable")
	}

	write(t, path, "export function one() {}\n")
	dirty := fingerprint(main)
	if dirty == clean {
		t.Fatal("edit not detected")
	}

	write(t, path, "export function two() { return 2 }\n")
	if fingerprint(main) == dirty {
		t.Fatal("second edit to a dirty file not detected")
	}

	run(t, main, gitBin, "commit", "-qam", "edit")
	if fingerprint(main) == clean {
		t.Fatal("commit not detected")
	}
}
