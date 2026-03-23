package config

import (
	"os"
	"path/filepath"
	"testing"
	"time"
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

func TestCheckConfigRejectsInvalidDatabaseConfig(t *testing.T) {
	tests := []struct {
		name    string
		mutate  func(cfg *Config)
		wantErr string
	}{
		{
			name: "missing enabled database host",
			mutate: func(cfg *Config) {
				cfg.Databases = []Database{{Enable: true, DbType: "postgres", DbName: "dudu-admin-api", DbUsername: "postgres", DbPassword: "secret"}}
			},
			wantErr: "databases[0].db_host cannot be null",
		},
		{
			name: "placeholder database host",
			mutate: func(cfg *Config) {
				cfg.Databases = []Database{{Enable: true, DbType: "postgres", DbHost: "db_host", DbName: "dudu-admin-api", DbUsername: "postgres", DbPassword: "secret"}}
			},
			wantErr: "databases[0].db_host contains template placeholder value \"db_host\"",
		},
		{
			name: "placeholder database username",
			mutate: func(cfg *Config) {
				cfg.Databases = []Database{{Enable: true, DbType: "postgres", DbHost: "127.0.0.1", DbName: "dudu-admin-api", DbUsername: "db_username", DbPassword: "secret"}}
			},
			wantErr: "databases[0].db_username contains template placeholder value \"db_username\"",
		},
		{
			name: "placeholder database password",
			mutate: func(cfg *Config) {
				cfg.Databases = []Database{{Enable: true, DbType: "postgres", DbHost: "127.0.0.1", DbName: "dudu-admin-api", DbUsername: "postgres", DbPassword: "db_password"}}
			},
			wantErr: "databases[0].db_password contains template placeholder value \"db_password\"",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := validTestConfig()
			tt.mutate(cfg)

			err := checkConfig(cfg)
			if err == nil {
				t.Fatalf("checkConfig() error = nil, want %q", tt.wantErr)
			}
			if err.Error() != tt.wantErr {
				t.Fatalf("checkConfig() error = %q, want %q", err.Error(), tt.wantErr)
			}
		})
	}
}

func TestCheckConfigRejectsInvalidRedisConfig(t *testing.T) {
	tests := []struct {
		name    string
		mutate  func(cfg *Config)
		wantErr string
	}{
		{
			name: "missing enabled redis name",
			mutate: func(cfg *Config) {
				cfg.Redis = []Redis{{Enable: true, Host: "127.0.0.1:6379"}}
			},
			wantErr: "redis[0].name cannot be null",
		},
		{
			name: "placeholder redis host",
			mutate: func(cfg *Config) {
				cfg.Redis = []Redis{{Enable: true, Name: "dudu-admin-api", Host: "host:6379"}}
			},
			wantErr: "redis[0].host contains template placeholder value \"host:6379\"",
		},
		{
			name: "missing enabled redis host",
			mutate: func(cfg *Config) {
				cfg.Redis = []Redis{{Enable: true, Name: "dudu-admin-api"}}
			},
			wantErr: "redis[0].host cannot be null",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := validTestConfig()
			tt.mutate(cfg)

			err := checkConfig(cfg)
			if err == nil {
				t.Fatalf("checkConfig() error = nil, want %q", tt.wantErr)
			}
			if err.Error() != tt.wantErr {
				t.Fatalf("checkConfig() error = %q, want %q", err.Error(), tt.wantErr)
			}
		})
	}
}

func TestCheckConfigAllowsEmptyAdminJWTSecret(t *testing.T) {
	cfg := validTestConfig()
	cfg.System.Admin.JwtSecret = ""

	if err := checkConfig(cfg); err != nil {
		t.Fatalf("checkConfig() error = %v, want nil", err)
	}
}

func validTestConfig() *Config {
	return &Config{
		System: SysConfig{
			Name:         "dudu-admin-api",
			RunMode:      "debug",
			HTTPPort:     ":8080",
			ReadTimeout:  60 * time.Second,
			WriteTimeout: 60 * time.Second,
			Version:      "1.0.0",
			DebugMode:    true,
			DefaultLang:  "zh-CN",
			JwtSecret:    "unit-test-secret",
			TokenExpire:  time.Hour,
		},
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
