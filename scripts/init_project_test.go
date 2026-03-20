package scripts_test

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestInitProjectDryRunDoesNotCreateArtifacts(t *testing.T) {
	repoRoot := repoRoot(t)
	scriptPath := filepath.Join(repoRoot, "scripts", "init-project.sh")
	projectRoot := createFakeRepoRoot(t)
	configDirRoot := t.TempDir()
	workdir := t.TempDir()
	customConfigPath := filepath.Join(configDirRoot, "custom", "bootstrap.json")

	output := runBashCommand(t, workdir, []string{
		"bash", scriptPath,
		"--non-interactive",
		"--dry-run",
		"--skip-clone",
		"--project-dir", projectRoot,
		"--dialect", "postgres",
		"--db-host", "127.0.0.1",
		"--db-name", "dudu-admin-api",
		"--db-user", "bootstrap",
		"--config", customConfigPath,
	})

	if _, err := os.Stat(filepath.Join(projectRoot, "bin", "tmp")); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("bin/tmp should not be created during dry-run, err = %v", err)
	}
	if _, err := os.Stat(filepath.Dir(customConfigPath)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("config parent dir should not be created during dry-run, err = %v", err)
	}
	if !strings.Contains(output, "[dry-run] write config to "+customConfigPath) {
		t.Fatalf("dry-run output missing config path, output = %s", output)
	}
	if !strings.Contains(output, "APP_CONFIG_PATH="+customConfigPath+" make run") {
		t.Fatalf("dry-run output missing explicit config run hint, output = %s", output)
	}
}

func TestEscapeSQLStringUsesSQLStandardQuoting(t *testing.T) {
	repoRoot := repoRoot(t)
	scriptPath := filepath.Join(repoRoot, "scripts", "init-project.sh")

	output := runBashCommandWithEnv(t, repoRoot, []string{"bash", "-lc", `
source "$SCRIPT_PATH" >/dev/null
print_info() { :; }
print_success() { :; }
psql() { printf '%s\n' "$*"; }
DRY_RUN=false
DIALECT=postgres
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=bootstrap
DB_PASSWORD=secret
DB_NAME=dudu-admin-api
ADMIN_EMAIL="$ADMIN_INPUT"
update_super_admin_if_needed
`}, []string{
		"SCRIPT_PATH=" + scriptPath,
		"ADMIN_INPUT=o'connor@example.com",
	})

	if !strings.Contains(output, "email='o''connor@example.com'") {
		t.Fatalf("postgres SQL should use doubled single quotes, output = %s", output)
	}
	if strings.Contains(output, `email='o\'\'connor@example.com'`) {
		t.Fatalf("postgres SQL should not use backslash escaping, output = %s", output)
	}
}

func repoRoot(t *testing.T) string {
	t.Helper()

	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Getwd() error = %v", err)
	}
	return filepath.Dir(wd)
}

func createFakeRepoRoot(t *testing.T) string {
	t.Helper()

	root := filepath.Join(t.TempDir(), "fake-repo")
	for _, dir := range []string{
		filepath.Join(root, "bin", "configs"),
		filepath.Join(root, "bin", "data", "sql"),
	} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatalf("MkdirAll(%q) error = %v", dir, err)
		}
	}

	if err := os.WriteFile(filepath.Join(root, "go.mod"), []byte("module example.com/fake\n\ngo 1.24.0\n"), 0o644); err != nil {
		t.Fatalf("WriteFile(go.mod) error = %v", err)
	}
	if err := os.WriteFile(filepath.Join(root, "main.go"), []byte("package main\n\nfunc main() {}\n"), 0o644); err != nil {
		t.Fatalf("WriteFile(main.go) error = %v", err)
	}

	return root
}

func runBashCommand(t *testing.T, workdir string, args []string) string {
	t.Helper()

	return runBashCommandWithEnv(t, workdir, args, nil)
}

func runBashCommandWithEnv(t *testing.T, workdir string, args []string, extraEnv []string) string {
	t.Helper()

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Dir = workdir
	cmd.Env = append(os.Environ(), extraEnv...)

	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("command %q failed: %v\n%s", strings.Join(args, " "), err, output)
	}
	return string(output)
}
