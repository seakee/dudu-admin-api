package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadConfigUsesExplicitConfigPath(t *testing.T) {
	t.Setenv(envKey, "local")

	tempDir := t.TempDir()
	fallbackPath := filepath.Join(tempDir, "bin", "configs", "local.json")
	explicitPath := filepath.Join(tempDir, "custom", "bootstrap.json")

	writeTestConfigFile(t, fallbackPath, "from-run-env")
	writeTestConfigFile(t, explicitPath, "from-explicit-path")

	originalWD, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd error: %v", err)
	}
	if err = os.Chdir(tempDir); err != nil {
		t.Fatalf("chdir error: %v", err)
	}
	t.Cleanup(func() {
		_ = os.Chdir(originalWD)
	})

	t.Setenv(configPathKey, explicitPath)

	resetConfigForTest(t)

	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("LoadConfig() error = %v", err)
	}
	if cfg.System.Name != "from-explicit-path" {
		t.Fatalf("System.Name = %q, want %q", cfg.System.Name, "from-explicit-path")
	}
	if cfg.System.Env != "local" {
		t.Fatalf("System.Env = %q, want %q", cfg.System.Env, "local")
	}
}

func TestLoadConfigFallsBackToRunEnvPath(t *testing.T) {
	t.Setenv(envKey, "test")

	tempDir := t.TempDir()
	configPath := filepath.Join(tempDir, "bin", "configs", "test.json")
	writeTestConfigFile(t, configPath, "from-run-env")

	originalWD, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd error: %v", err)
	}
	if err = os.Chdir(tempDir); err != nil {
		t.Fatalf("chdir error: %v", err)
	}
	t.Cleanup(func() {
		_ = os.Chdir(originalWD)
	})

	resetConfigForTest(t)

	cfg, err := LoadConfig()
	if err != nil {
		t.Fatalf("LoadConfig() error = %v", err)
	}
	if cfg.System.Name != "from-run-env" {
		t.Fatalf("System.Name = %q, want %q", cfg.System.Name, "from-run-env")
	}
	if cfg.System.RoutePrefix != "dudu-admin-api" {
		t.Fatalf("System.RoutePrefix = %q, want %q", cfg.System.RoutePrefix, "dudu-admin-api")
	}
}

func resetConfigForTest(t *testing.T) {
	t.Helper()

	previous := config
	config = nil
	t.Cleanup(func() {
		config = previous
	})
}

func writeTestConfigFile(t *testing.T, path string, name string) {
	t.Helper()

	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("MkdirAll(%q) error = %v", path, err)
	}

	content := `{
  "system": {
    "name": "` + name + `",
    "run_mode": "debug",
    "http_port": ":8080",
    "read_timeout": 60,
    "write_timeout": 60,
    "version": "1.0.0",
    "debug_mode": true,
    "default_lang": "zh-CN",
    "jwt_secret": "unit-test-secret",
    "token_expire": 3600,
    "admin": {
      "auth_rate_limit": {
        "enable": true,
        "window_seconds": 60,
        "max_requests": 20
      }
    }
  }
}`

	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("WriteFile(%q) error = %v", path, err)
	}
}
