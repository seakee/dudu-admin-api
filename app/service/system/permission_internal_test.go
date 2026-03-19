package system

import "testing"

func TestIsAdminRoutePath(t *testing.T) {
	tests := []struct {
		path string
		want bool
	}{
		{path: "/dudu-admin-api/internal/admin/system/user", want: true},
		{path: "/dudu-admin-api/internal/admin/system/user", want: true},
		{path: "/internal/admin/system/user", want: true},
		{path: "/dudu-admin-api/internal/service/ping", want: false},
		{path: "/dudu-admin-api/external/service/ping", want: false},
	}

	for _, tt := range tests {
		if got := isAdminRoutePath(tt.path); got != tt.want {
			t.Fatalf("isAdminRoutePath(%q) = %v, want %v", tt.path, got, tt.want)
		}
	}
}
