package main

import (
	"strings"
	"testing"
)

func TestFormatLocators(t *testing.T) {
	tests := []struct {
		name string
		raw  string
		want []string
	}{
		{
			name: "keeps strong named hits",
			raw: `[
				{"score": 90, "node": {"kind": "function", "name": "mkChecks", "qualifiedName": "parts::mkChecks", "filePath": "parts/checks.nix", "startLine": 3}},
				{"score": 40, "node": {"kind": "variable", "name": "filter", "filePath": "lib.nix", "startLine": 9}}
			]`,
			want: []string{
				"- function parts::mkChecks — parts/checks.nix:3",
				"- variable filter — lib.nix:9",
			},
		},
		{
			name: "drops weak, short and pathless hits, then too few remain",
			raw: `[
				{"score": 90, "node": {"kind": "function", "name": "mkChecks", "filePath": "a.nix", "startLine": 1}},
				{"score": 20, "node": {"kind": "function", "name": "weakling", "filePath": "b.nix", "startLine": 1}},
				{"score": 76, "node": {"kind": "variable", "name": "for", "filePath": "c.nix", "startLine": 1}},
				{"score": 80, "node": {"kind": "module", "name": "external", "filePath": null, "startLine": 1}}
			]`,
		},
		{
			name: "rejects garbage",
			raw:  `not json`,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := formatLocators([]byte(tt.raw))
			if tt.want == nil {
				if got != "" {
					t.Fatalf("want empty, got %q", got)
				}
				return
			}
			want := header + "\n" + strings.Join(tt.want, "\n")
			if got != want {
				t.Fatalf("got\n%s\nwant\n%s", got, want)
			}
		})
	}
}
