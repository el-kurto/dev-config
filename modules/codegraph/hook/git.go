package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func git(dir string, args ...string) (string, error) {
	out, err := gitRaw(dir, args...)
	return strings.TrimSpace(out), err
}

func gitRaw(dir string, args ...string) (string, error) {
	out, err := exec.Command(gitBin, append([]string{"-C", dir}, args...)...).Output()
	return string(out), err
}

func rootOf(path string) (string, bool) {
	if path == "" {
		return "", false
	}
	for !isDir(path) {
		parent := filepath.Dir(path)
		if parent == path {
			return "", false
		}
		path = parent
	}
	root, err := git(path, "rev-parse", "--show-toplevel")
	return root, err == nil && root != ""
}

func roots(dir string) []string {
	if root, ok := rootOf(dir); ok {
		return []string{root}
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var found []string
	for _, e := range entries {
		child := filepath.Join(dir, e.Name())
		if e.IsDir() && exists(filepath.Join(child, ".git")) && indexed(child) {
			found = append(found, child)
		}
	}
	return found
}

func worktrees(root string) []string {
	out, err := git(root, "worktree", "list", "--porcelain")
	if err != nil {
		return nil
	}
	var paths []string
	for line := range strings.Lines(out) {
		if path, ok := strings.CutPrefix(strings.TrimSpace(line), "worktree "); ok {
			paths = append(paths, path)
		}
	}
	return paths
}

func targets(dir string) []string {
	var found []string
	seen := map[string]bool{}
	for _, root := range roots(dir) {
		for _, wt := range append([]string{root}, worktrees(root)...) {
			if seen[wt] || (wt != root && !indexed(wt)) {
				continue
			}
			seen[wt] = true
			found = append(found, wt)
		}
	}
	return found
}

func reflogs(dir string) []string {
	paths := []string{}
	seen := map[string]bool{}
	for _, wt := range targets(dir) {
		if p := reflogOf(wt); p != "" && !seen[p] {
			seen[p] = true
			paths = append(paths, p)
		}
	}
	return paths
}

func reflogOf(worktree string) string {
	dotgit := filepath.Join(worktree, ".git")
	if isDir(dotgit) {
		return filepath.Join(dotgit, "logs", "HEAD")
	}
	link, err := os.ReadFile(dotgit)
	if err != nil {
		return ""
	}
	gitDir, ok := strings.CutPrefix(strings.TrimSpace(string(link)), "gitdir: ")
	if !ok {
		return ""
	}
	if !filepath.IsAbs(gitDir) {
		gitDir = filepath.Join(worktree, gitDir)
	}
	return filepath.Join(gitDir, "logs", "HEAD")
}

func isDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
