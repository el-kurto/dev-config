package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
	"unicode/utf8"
)

const (
	minQueryRunes = 12
	maxQueryRunes = 2000
	minScore      = 35
	minNameRunes  = 4
	minHits       = 2
	header        = "[codegraph] possibly relevant symbols — pull the source with `codegraph explore \"<what you need>\"`, trace impact with `codegraph impact <symbol>`:"
)

type hit struct {
	Score float64 `json:"score"`
	Node  struct {
		Kind          string  `json:"kind"`
		Name          string  `json:"name"`
		QualifiedName string  `json:"qualifiedName"`
		FilePath      *string `json:"filePath"`
		StartLine     int     `json:"startLine"`
	} `json:"node"`
}

// `query`, not `explore`: explore inlines full source (~4k tokens for two
// files) and this is fresh full-price input on every turn. Locators let the
// model pull only the spans it wants.
func locators(root, query string) string {
	if utf8.RuneCountInString(query) < minQueryRunes || !indexed(root) {
		return ""
	}
	if r := []rune(query); len(r) > maxQueryRunes {
		query = string(r[:maxQueryRunes])
	}
	cmd := exec.Command(codegraphBin, "query", "--json", "--limit", "5", "--", query)
	cmd.Dir = root
	out, err := cmd.Output()
	if err != nil {
		return ""
	}
	return formatLocators(out)
}

// Three filters, because a prompt with no code in it still matches something.
// Scores are absolute rather than normalised, so a floor is meaningful — but a
// floor alone is not enough: one stopword against a variable literally named
// `right` scored 76 while the rest sat at 18.
//
// The names are what actually separate noise from signal. Every false positive
// so far matched a short English word that happens to be an identifier — `for`
// (the Prometheus alert attribute, five times over), `Is`, `right`. Real hits
// are `mkChecks`, `filter`, `description`. Four characters is the cut, and
// repetition is deliberately not penalised: `mkChecks` five times across
// parts/checks is the answer to "what does mkChecks do", not noise.
func formatLocators(raw []byte) string {
	var hits []hit
	if json.Unmarshal(raw, &hits) != nil {
		return ""
	}
	var lines []string
	for _, h := range hits {
		n := h.Node
		if h.Score < minScore || n.FilePath == nil || utf8.RuneCountInString(n.Name) < minNameRunes {
			continue
		}
		lines = append(lines, fmt.Sprintf("- %s %s — %s:%d", n.Kind, first(n.QualifiedName, n.Name), *n.FilePath, n.StartLine))
	}
	if len(lines) < minHits {
		return ""
	}
	return header + "\n" + strings.Join(lines, "\n")
}
