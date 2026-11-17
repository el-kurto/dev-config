package main

import (
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"slices"
	"time"
)

const handoffTTL = 2 * time.Minute

var handoffRoot = filepath.Join(os.TempDir(), "codegraph-hook", "handoff")

func handoffDir(session, agentType string) string {
	return filepath.Join(handoffRoot, url.PathEscape(first(session, "-")), url.PathEscape(first(agentType, "general-purpose")))
}

func stash(session, agentType, ctx string) {
	dir := handoffDir(session, agentType)
	if os.MkdirAll(dir, 0o700) != nil {
		return
	}
	name := fmt.Sprintf("%020d-%d", time.Now().UnixNano(), os.Getpid())
	tmp := filepath.Join(dir, "."+name)
	if os.WriteFile(tmp, []byte(ctx), 0o600) != nil {
		return
	}
	_ = os.Rename(tmp, filepath.Join(dir, name))
}

func claim(session, agentType string) string {
	dir := handoffDir(session, agentType)
	entries, err := os.ReadDir(dir)
	if err != nil {
		return ""
	}
	names := make([]string, 0, len(entries))
	for _, e := range entries {
		if n := e.Name(); n[0] != '.' {
			names = append(names, n)
		}
	}
	slices.Sort(names)
	for _, n := range names {
		path := filepath.Join(dir, n)
		info, err := os.Stat(path)
		if err != nil {
			continue
		}
		taken := filepath.Join(dir, ".taken-"+n)
		if os.Rename(path, taken) != nil {
			continue
		}
		data, err := os.ReadFile(taken)
		_ = os.Remove(taken)
		if err != nil || time.Since(info.ModTime()) > handoffTTL {
			continue
		}
		return string(data)
	}
	return ""
}
