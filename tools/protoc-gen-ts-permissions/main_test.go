package main

import (
	"strings"
	"testing"
)

func TestKey(t *testing.T) {
	for in, want := range map[string]string{"user:read": "userRead", "permission:register": "permissionRegister", "a-b_c.d:e": "aBCDE", "word:write": "wordWrite"} {
		if got := key(in); got != want {
			t.Errorf("key(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestRender(t *testing.T) {
	src, err := render(map[string][]permission{
		"identity": {{"identity:user:write", "Create users"}, {"identity:user:read", "Read users"}},
		"bill":     {{"bill:invoice:read", ""}},
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		`userRead: "identity:user:read"`, `userWrite: "identity:user:write"`, `invoiceRead: "bill:invoice:read"`,
		"export type Permission", "export const PERMISSIONS", "/** Read users */",
	} {
		if !strings.Contains(src, want) {
			t.Errorf("missing %q in\n%s", want, src)
		}
	}
	if strings.Index(src, "  bill: {") > strings.Index(src, "  identity: {") {
		t.Error("services are sorted")
	}
	if _, err := render(map[string][]permission{"a": {{"a:x-y:z", ""}, {"a:x:y-z", ""}}}); err == nil {
		t.Error("two names with one key must fail")
	}
}
