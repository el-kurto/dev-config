package main

import (
	"encoding/json"
	"os"
)

var (
	gitBin       = "git"
	codegraphBin = "codegraph"
)

type input struct {
	Event     string          `json:"hook_event_name"`
	SessionID string          `json:"session_id"`
	AgentType string          `json:"agent_type"`
	Cwd       string          `json:"cwd"`
	Prompt    string          `json:"prompt"`
	ToolName  string          `json:"tool_name"`
	ToolInput json.RawMessage `json:"tool_input"`
	NewCwd    string          `json:"new_cwd"`
	Directory string          `json:"directory"`
	FilePath  string          `json:"file_path"`
}

type output struct {
	HookSpecificOutput map[string]any `json:"hookSpecificOutput"`
}

func main() {
	if len(os.Args) > 2 && os.Args[1] == "refresh" {
		for _, root := range os.Args[2:] {
			refresh(root, false)
		}
		return
	}

	var in input
	if err := json.NewDecoder(os.Stdin).Decode(&in); err != nil {
		return
	}
	out := handle(in)
	if out == nil {
		return
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetEscapeHTML(false)
	_ = enc.Encode(out)
}

func handle(in input) *output {
	switch in.Event {
	case "SessionStart", "CwdChanged":
		cwd := first(in.NewCwd, in.Cwd)
		spawn(targets(cwd)...)
		return hookOutput(in.Event, "watchPaths", reflogs(cwd))

	case "DirectoryAdded":
		if root, ok := rootOf(in.Directory); ok {
			spawn(root)
		}

	case "FileChanged":
		for _, wt := range targets(in.Cwd) {
			if reflogOf(wt) == in.FilePath && indexed(wt) {
				spawn(wt)
			}
		}
		return hookOutput(in.Event, "watchPaths", reflogs(in.Cwd))

	case "PostToolUse":
		if in.ToolName == "Bash" {
			spawn(targets(in.Cwd)...)
			return nil
		}
		var tool struct {
			FilePath     string `json:"file_path"`
			NotebookPath string `json:"notebook_path"`
		}
		_ = json.Unmarshal(in.ToolInput, &tool)
		if root, ok := rootOf(first(tool.FilePath, tool.NotebookPath, in.Cwd)); ok {
			ensure(root)
		}

	case "UserPromptSubmit":
		root, ok := rootOf(in.Cwd)
		if !ok {
			return nil
		}
		if ctx := locators(root, in.Prompt); ctx != "" {
			return hookOutput(in.Event, "additionalContext", ctx)
		}

	case "PreToolUse":
		if in.ToolName != "Agent" && in.ToolName != "Task" {
			return nil
		}
		var tool struct {
			Prompt       string `json:"prompt"`
			SubagentType string `json:"subagent_type"`
		}
		if json.Unmarshal(in.ToolInput, &tool) != nil {
			return nil
		}
		if root, ok := rootOf(in.Cwd); ok {
			if ctx := locators(root, tool.Prompt); ctx != "" {
				stash(in.SessionID, tool.SubagentType, ctx)
			}
		}

	case "SubagentStart":
		if ctx := claim(in.SessionID, in.AgentType); ctx != "" {
			return hookOutput(in.Event, "additionalContext", ctx)
		}
	}
	return nil
}

func hookOutput(event, key string, value any) *output {
	return &output{HookSpecificOutput: map[string]any{"hookEventName": event, key: value}}
}

func first(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}
