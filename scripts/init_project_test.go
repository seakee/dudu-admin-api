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

func TestInitProjectScriptUsesEnglishPrompts(t *testing.T) {
	repoRoot := repoRoot(t)
	scriptPath := filepath.Join(repoRoot, "scripts", "init-project.sh")

	content, err := os.ReadFile(scriptPath)
	if err != nil {
		t.Fatalf("ReadFile(%q) error = %v", scriptPath, err)
	}

	script := string(content)

	for _, phrase := range []string{
		"项目目录（若不存在将自动 clone）",
		"进入交互式配置向导",
		"运行环境 RUN_ENV",
		"数据库类型 (mysql/postgres)",
		"redis.auth (可留空)",
		"是否覆盖超级管理员（user_id=1）账号字段？",
		"admin password (留空则不改)",
		"即将执行 init.sql，数据库 [$DB_NAME] 的相关表会被重置（DROP TABLE）",
		"确认继续执行？",
		"确认写入配置并执行初始化？",
		"已取消。",
	} {
		if strings.Contains(script, phrase) {
			t.Fatalf("script still contains Chinese prompt %q", phrase)
		}
	}

	for _, phrase := range []string{
		`"Project name"`,
		`"Go module name"`,
		`"Project directory"`,
		`"Starting interactive configuration wizard"`,
		`"Runtime environment RUN_ENV"`,
		`"Database dialect (mysql/postgres)"`,
		`"redis.auth (optional)"`,
		`"Override super admin (user_id=1) account fields?"`,
		`"admin password (leave blank to keep unchanged)"`,
		`"About to execute init.sql. Related tables in database [$DB_NAME] will be reset (DROP TABLE)."`,
		`"Continue?"`,
		`"Write the config and run initialization?"`,
		`"Cancelled."`,
	} {
		if !strings.Contains(script, phrase) {
			t.Fatalf("script missing expected English prompt %q", phrase)
		}
	}
}

func TestInitProjectGenerateModeDryRunUsesCurrentRepoAsTemplateSource(t *testing.T) {
	repoRoot := repoRoot(t)
	scriptPath := filepath.Join(repoRoot, "scripts", "init-project.sh")
	targetDir := filepath.Join(t.TempDir(), "my-api")

	output := runBashCommand(t, repoRoot, []string{
		"bash", scriptPath,
		"--non-interactive",
		"--dry-run",
		"--yes",
		"--skip-go-mod",
		"--project-name", "my-api",
		"--module-name", "github.com/acme/my-api",
		"--project-dir", targetDir,
		"--dialect", "postgres",
		"--db-password", "secret",
	})

	if !strings.Contains(output, "[dry-run] git clone -b main --depth 1 "+repoRoot+" "+targetDir) {
		t.Fatalf("dry-run should use current repo as default template source, output = %s", output)
	}
	if !strings.Contains(output, "Generate project: name=my-api module=github.com/acme/my-api dir="+targetDir) {
		t.Fatalf("dry-run output missing generation summary, output = %s", output)
	}
	if !strings.Contains(output, "DB: my-api@127.0.0.1:5432 (user: my-api)") {
		t.Fatalf("dry-run output missing generated database defaults, output = %s", output)
	}
	if !strings.Contains(output, "System: name=my-api run_mode=release route_prefix=my-api effective_prefix=my-api") {
		t.Fatalf("dry-run output missing generated system defaults, output = %s", output)
	}
}

func TestInitProjectGenerateModeRequiresRepoURLForNonRemoteModuleOutsideTemplateRepo(t *testing.T) {
	repoRoot := repoRoot(t)
	originalScriptPath := filepath.Join(repoRoot, "scripts", "init-project.sh")
	workdir := t.TempDir()
	targetDir := filepath.Join(workdir, "my-api")
	scriptCopyPath := filepath.Join(workdir, "init-project.sh")

	content, err := os.ReadFile(originalScriptPath)
	if err != nil {
		t.Fatalf("ReadFile(%q) error = %v", originalScriptPath, err)
	}

	script := strings.ReplaceAll(string(content), `TEMPLATE_MODULE_NAME="github.com/seakee/dudu-admin-api"`, `TEMPLATE_MODULE_NAME="template-local"`)
	if err := os.WriteFile(scriptCopyPath, []byte(script), 0o755); err != nil {
		t.Fatalf("WriteFile(%q) error = %v", scriptCopyPath, err)
	}

	output := runBashCommandExpectError(t, workdir, []string{
		"bash", scriptCopyPath,
		"--non-interactive",
		"--yes",
		"--skip-go-mod",
		"--project-name", "my-api",
		"--module-name", "my-api",
		"--project-dir", targetDir,
		"--dialect", "postgres",
		"--db-password", "secret",
	})

	if !strings.Contains(output, "Template repository URL is empty") {
		t.Fatalf("expected explicit repo-url guidance for non-remote module name, output = %s", output)
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

func runBashCommandExpectError(t *testing.T, workdir string, args []string) string {
	t.Helper()

	cmd := exec.Command(args[0], args[1:]...)
	cmd.Dir = workdir
	cmd.Env = os.Environ()

	output, err := cmd.CombinedOutput()
	if err == nil {
		t.Fatalf("command %q succeeded unexpectedly\n%s", strings.Join(args, " "), output)
	}
	return string(output)
}
