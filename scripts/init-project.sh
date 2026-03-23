#!/usr/bin/env bash

# Project bootstrap script.
# Supports:
# 1) Generate a brand-new project from a template source
# 2) Initialize the current or an existing project repository
# 3) Interactive wizard (default) to generate minimal runnable config

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { printf "${BLUE}%-9s${NC} %s\n" "[INFO]" "$1"; }
print_success() { printf "${GREEN}%-9s${NC} %s\n" "[SUCCESS]" "$1"; }
print_warning() { printf "${YELLOW}%-9s${NC} %s\n" "[WARNING]" "$1"; }
print_error() { printf "${RED}%-9s${NC} %s\n" "[ERROR]" "$1"; }

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
CURRENT_DIR="$(pwd)"
PROJECT_ROOT=""

TEMPLATE_PROJECT_NAME="dudu-admin-api"
TEMPLATE_MODULE_NAME="github.com/seakee/dudu-admin-api"

REPO_URL=""
REPO_REF="main"
PROJECT_DIR=""
PROJECT_NAME=""
MODULE_NAME=""
GENERATE_PROJECT=false

INTERACTIVE=false
NON_INTERACTIVE=false
YES=false
DRY_RUN=false
CREATE_DB=true
SKIP_GO_MOD=false
SKIP_CLONE=false

PROJECT_DIR_SET=false
PROJECT_NAME_SET=false
MODULE_NAME_SET=false
SYSTEM_NAME_SET=false
SYSTEM_ROUTE_PREFIX_SET=false
DB_NAME_SET=false
DB_USER_SET=false

RUN_ENV="local"
CONFIG_PATH=""
DIALECT=""
SQL_FILE=""
EXEC_SQL_FILE=""

SYSTEM_NAME="$TEMPLATE_PROJECT_NAME"
SYSTEM_ROUTE_PREFIX="$TEMPLATE_PROJECT_NAME"
SYSTEM_RUN_MODE="release"
SYSTEM_HTTP_PORT=":8080"
SYSTEM_DEFAULT_LANG="zh-CN"
SYSTEM_READ_TIMEOUT="60"
SYSTEM_WRITE_TIMEOUT="60"
SYSTEM_VERSION="1.0.0"
SYSTEM_DEBUG_MODE="false"
SYSTEM_TOKEN_EXPIRE="604800"
SYSTEM_JWT_SECRET=""
ADMIN_JWT_SECRET=""
ADMIN_TOKEN_EXPIRE_IN="2592000"

DB_HOST="127.0.0.1"
DB_PORT=""
DB_NAME="$TEMPLATE_PROJECT_NAME"
DB_USER="$TEMPLATE_PROJECT_NAME"
DB_PASSWORD=""
DB_SSL_MODE="disable"
DB_TIMEZONE="Asia/Shanghai"

REDIS_HOST="127.0.0.1:6379"
REDIS_AUTH=""
REDIS_DB="0"

ADMIN_EMAIL=""
ADMIN_PHONE=""
ADMIN_USERNAME=""
ADMIN_PASSWORD=""

tmp_files=()

cleanup() {
    for f in "${tmp_files[@]:-}"; do
        if [[ -n "$f" && -f "$f" ]]; then
            rm -f "$f"
        fi
    done
    return 0
}
trap cleanup EXIT

show_usage() {
    cat <<'EOF'
Usage:
  ./init-project.sh [options]

Modes:
  1) Generate a new project from a template source, then initialize it
  2) Initialize the current/existing project repository

Template source priority in generate mode:
  1) --repo-url
  2) Current repository working tree (when running inside repo)
  3) Default remote template repository inferred from template module path

Interactive mode is enabled by default when stdin is a TTY.

Options:
  --interactive              Force interactive wizard mode
  --non-interactive          Disable prompts and use CLI/default values
  --yes                      Skip destructive confirmation
  --dry-run                  Print actions only
  --skip-go-mod              Skip `go mod download`
  --create-db                Create DB if not exists (default)
  --no-create-db             Do not create DB

  --project-name <name>      Generate a new project with this name
  --module-name <name>       Go module name for generated project
  --project-dir <path>       Target project directory
  --skip-clone               Do not clone template automatically when generation is needed
  --repo-url <url>           Template repository URL or local git repo path for clone
  --repo-ref <ref>           Template branch/tag, default: main

Notes:
  - If --module-name is not a remote repository path, pass --repo-url explicitly when not running inside the template repo
  - In generate mode, running this script inside the template repo will use the current repo as the template source by default

  --env <name>               Config env name, default: local
  --config <path>            Config path, default: {project}/bin/configs/{env}.json
  --dialect <mysql|postgres>
  --sql-file <path>          Custom init SQL path

  --name <value>             system.name
  --route-prefix <value>     system.route_prefix
  --run-mode <debug|release> system.run_mode
  --http-port <value>        system.http_port
  --default-lang <value>     system.default_lang
  --jwt-secret <value>       system.jwt_secret
  --admin-jwt-secret <value> system.admin.jwt_secret

  --db-host <host>
  --db-port <port>
  --db-name <name>
  --db-user <user>
  --db-password <password>
  --db-ssl-mode <mode>       Postgres only
  --db-timezone <timezone>   Postgres only

  --redis-host <host:port>
  --redis-auth <password>
  --redis-db <index>

  --admin-email <email>
  --admin-phone <phone>
  --admin-username <username>
  --admin-password <password>
EOF
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        print_error "Missing required command: $1"
        exit 1
    fi
}

escape_sql_string() {
    local input="$1"
    printf "%s" "$input" | sed "s/'/''/g"
}

trim_slashes() {
    local value="$1"
    while [[ "$value" == /* ]]; do
        value="${value#/}"
    done
    while [[ "$value" == */ ]]; do
        value="${value%/}"
    done
    printf "%s" "$value"
}

effective_route_prefix() {
    local prefix
    prefix="$(trim_slashes "$SYSTEM_ROUTE_PREFIX")"
    if [[ -z "$prefix" ]]; then
        prefix="$TEMPLATE_PROJECT_NAME"
    fi
    printf "%s" "$prefix"
}

default_repo_url_for_module() {
    local module_name="$1"
    if [[ "$module_name" == *.*/* ]]; then
        printf "https://%s.git" "$module_name"
        return
    fi
    printf ""
}

resolve_template_source() {
    if [[ -n "$REPO_URL" ]]; then
        return
    fi

    if is_repo_root "$CURRENT_DIR"; then
        REPO_URL="$CURRENT_DIR"
        return
    fi

    if is_repo_root "$SCRIPT_DIR/.."; then
        REPO_URL="$(cd "$SCRIPT_DIR/.." && pwd)"
        return
    fi

    REPO_URL="$(default_repo_url_for_module "$TEMPLATE_MODULE_NAME")"
}

escape_sed_replacement() {
    local input="$1"
    input="${input//\\/\\\\}"
    input="${input//&/\\&}"
    input="${input//|/\\|}"
    printf "%s" "$input"
}

escape_sed_pattern() {
    printf "%s" "$1" | sed -e 's/[][\\/.^$*+?(){}|]/\\&/g'
}

make_temp_go_file() {
    local tmp_file
    if [[ -n "$PROJECT_ROOT" && -d "$PROJECT_ROOT" ]]; then
        local dir="$PROJECT_ROOT/bin/tmp/init-project"
        mkdir -p "$dir"
        tmp_file="$(mktemp "$dir/init-project-XXXXXX")"
    else
        tmp_file="$(mktemp)"
    fi

    mv "$tmp_file" "${tmp_file}.go"
    printf "%s" "${tmp_file}.go"
}

go_run_in_project() {
    local main_file="$1"
    shift

    if [[ -z "$PROJECT_ROOT" || ! -d "$PROJECT_ROOT" ]]; then
        print_error "Project root is not ready: $PROJECT_ROOT"
        exit 1
    fi

    (cd "$PROJECT_ROOT" && go run "$main_file" "$@")
}

prepare_exec_sql_file() {
    local source="$SQL_FILE"
    EXEC_SQL_FILE="$source"

    if [[ ! -f "$source" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] init SQL source: $source"
            return
        fi
        print_error "Init SQL file not found: $source"
        exit 1
    fi

    local prefix
    prefix="$(effective_route_prefix)"
    if [[ "$prefix" == "$TEMPLATE_PROJECT_NAME" ]]; then
        return
    fi

    local escaped_prefix
    escaped_prefix="$(escape_sed_replacement "$prefix")"
    local tmp_sql
    tmp_sql="$(mktemp)"
    tmp_files+=("$tmp_sql")

    sed "s|/${TEMPLATE_PROJECT_NAME}/|/${escaped_prefix}/|g" "$source" > "$tmp_sql"
    EXEC_SQL_FILE="$tmp_sql"

    print_info "Adjusted init SQL permission paths to prefix: /$prefix"
}

postgres_can_connect_db() {
    local db_name="$1"
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db_name" -tAc "SELECT 1" >/dev/null 2>&1
}

is_repo_root() {
    local dir="$1"
    [[ -f "$dir/go.mod" && -f "$dir/main.go" && -d "$dir/bin/configs" && -d "$dir/bin/data/sql" ]]
}

basename_from_path() {
    local value="$1"
    value="${value%/}"
    if [[ -z "$value" ]]; then
        printf "%s" "$TEMPLATE_PROJECT_NAME"
        return
    fi
    printf "%s" "${value##*/}"
}

ask_with_default() {
    local prompt="$1"
    local default_value="${2:-}"
    local value=""
    if [[ "$INTERACTIVE" != true ]]; then
        printf "%s" "$default_value"
        return
    fi
    if [[ -n "$default_value" ]]; then
        read -r -p "$prompt [$default_value]: " value
    else
        read -r -p "$prompt: " value
    fi
    if [[ -z "$value" ]]; then
        value="$default_value"
    fi
    printf "%s" "$value"
}

ask_secret_with_default() {
    local prompt="$1"
    local default_value="${2:-}"
    local value=""
    if [[ "$INTERACTIVE" != true ]]; then
        printf "%s" "$default_value"
        return
    fi
    if [[ -n "$default_value" ]]; then
        printf "%s [******]: " "$prompt"
    else
        printf "%s: " "$prompt"
    fi
    stty -echo
    read -r value
    stty echo
    printf "\n"
    if [[ -z "$value" ]]; then
        value="$default_value"
    fi
    printf "%s" "$value"
}

ask_yes_no() {
    local prompt="$1"
    local default="${2:-N}"
    local answer=""
    if [[ "$INTERACTIVE" != true ]]; then
        [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
    read -r -p "$prompt (${default}/$([[ "$default" =~ ^[Yy]$ ]] && echo n || echo y)): " answer
    if [[ -z "$answer" ]]; then
        answer="$default"
    fi
    [[ "$answer" =~ ^[Yy]$ ]]
}

generate_secret() {
    local length="${1:-64}"
    local tmp_go
    tmp_go="$(make_temp_go_file)"
    tmp_files+=("$tmp_go")

    cat > "$tmp_go" <<'EOF'
package main

import (
	"crypto/rand"
	"fmt"
	"os"
	"strconv"
)

const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func main() {
	n := 64
	if len(os.Args) > 1 {
		v, err := strconv.Atoi(os.Args[1])
		if err == nil && v > 0 {
			n = v
		}
	}
	buf := make([]byte, n)
	randBuf := make([]byte, n)
	if _, err := rand.Read(randBuf); err != nil {
		os.Exit(1)
	}
	for i := range buf {
		buf[i] = alphabet[int(randBuf[i])%len(alphabet)]
	}
	fmt.Print(string(buf))
}
EOF

    go run "$tmp_go" "$length"
}

hash_admin_password() {
    local plain="$1"
    local tmp_go
    tmp_go="$(make_temp_go_file)"
    tmp_files+=("$tmp_go")

    cat > "$tmp_go" <<'EOF'
package main

import (
	"crypto/md5"
	"fmt"
	"os"

	"golang.org/x/crypto/bcrypt"
)

func main() {
	if len(os.Args) != 2 {
		os.Exit(1)
	}
	digest := md5.Sum([]byte(os.Args[1]))
	credential := fmt.Sprintf("%x", digest)
	hash, err := bcrypt.GenerateFromPassword([]byte(credential), 12)
	if err != nil {
		os.Exit(1)
	}
	fmt.Print(string(hash))
}
EOF

    go_run_in_project "$tmp_go" "$plain"
}

validate_project_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        print_error "Project name cannot be empty"
        exit 1
    fi

    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid project name: '$name'. Only letters, numbers, hyphens, and underscores are allowed."
        exit 1
    fi

    if [[ ${#name} -lt 2 ]]; then
        print_error "Project name must be at least 2 characters long."
        exit 1
    fi

    if [[ ${#name} -gt 100 ]]; then
        print_error "Project name is too long (max 100 characters)."
        exit 1
    fi
}

validate_module_name() {
    local module_name="$1"

    if [[ -z "$module_name" ]]; then
        print_error "Module name cannot be empty"
        exit 1
    fi

    if [[ "$module_name" =~ [A-Z[:space:]] ]]; then
        print_error "Invalid module name: '$module_name'"
        print_error "Go module names should be lowercase and contain no spaces"
        print_error "Valid examples: my-project, github.com/user/project"
        exit 1
    fi
}

apply_project_defaults() {
    if [[ "$GENERATE_PROJECT" != true ]]; then
        return
    fi

    if [[ "$SYSTEM_NAME_SET" != true ]]; then
        SYSTEM_NAME="$PROJECT_NAME"
    fi
    if [[ "$SYSTEM_ROUTE_PREFIX_SET" != true ]]; then
        SYSTEM_ROUTE_PREFIX="$PROJECT_NAME"
    fi
    if [[ "$DB_NAME_SET" != true ]]; then
        DB_NAME="$PROJECT_NAME"
    fi
    if [[ "$DB_USER_SET" != true ]]; then
        DB_USER="$PROJECT_NAME"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive) INTERACTIVE=true; shift ;;
            --non-interactive) NON_INTERACTIVE=true; shift ;;
            --yes) YES=true; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --skip-go-mod) SKIP_GO_MOD=true; shift ;;
            --skip-clone) SKIP_CLONE=true; shift ;;
            --create-db) CREATE_DB=true; shift ;;
            --no-create-db) CREATE_DB=false; shift ;;
            --project-name) PROJECT_NAME="$2"; PROJECT_NAME_SET=true; shift 2 ;;
            --module-name) MODULE_NAME="$2"; MODULE_NAME_SET=true; shift 2 ;;
            --project-dir) PROJECT_DIR="$2"; PROJECT_DIR_SET=true; shift 2 ;;
            --repo-url) REPO_URL="$2"; shift 2 ;;
            --repo-ref) REPO_REF="$2"; shift 2 ;;
            --env) RUN_ENV="$2"; shift 2 ;;
            --config) CONFIG_PATH="$2"; shift 2 ;;
            --dialect) DIALECT="$2"; shift 2 ;;
            --sql-file) SQL_FILE="$2"; shift 2 ;;
            --name) SYSTEM_NAME="$2"; SYSTEM_NAME_SET=true; shift 2 ;;
            --route-prefix) SYSTEM_ROUTE_PREFIX="$2"; SYSTEM_ROUTE_PREFIX_SET=true; shift 2 ;;
            --run-mode) SYSTEM_RUN_MODE="$2"; shift 2 ;;
            --http-port) SYSTEM_HTTP_PORT="$2"; shift 2 ;;
            --default-lang) SYSTEM_DEFAULT_LANG="$2"; shift 2 ;;
            --jwt-secret) SYSTEM_JWT_SECRET="$2"; shift 2 ;;
            --admin-jwt-secret) ADMIN_JWT_SECRET="$2"; shift 2 ;;
            --db-host) DB_HOST="$2"; shift 2 ;;
            --db-port) DB_PORT="$2"; shift 2 ;;
            --db-name) DB_NAME="$2"; DB_NAME_SET=true; shift 2 ;;
            --db-user) DB_USER="$2"; DB_USER_SET=true; shift 2 ;;
            --db-password) DB_PASSWORD="$2"; shift 2 ;;
            --db-ssl-mode) DB_SSL_MODE="$2"; shift 2 ;;
            --db-timezone) DB_TIMEZONE="$2"; shift 2 ;;
            --redis-host) REDIS_HOST="$2"; shift 2 ;;
            --redis-auth) REDIS_AUTH="$2"; shift 2 ;;
            --redis-db) REDIS_DB="$2"; shift 2 ;;
            --admin-email) ADMIN_EMAIL="$2"; shift 2 ;;
            --admin-phone) ADMIN_PHONE="$2"; shift 2 ;;
            --admin-username) ADMIN_USERNAME="$2"; shift 2 ;;
            --admin-password) ADMIN_PASSWORD="$2"; shift 2 ;;
            -h|--help) show_usage; exit 0 ;;
            *)
                print_error "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

resolve_interactive_mode() {
    if [[ "$NON_INTERACTIVE" == true ]]; then
        INTERACTIVE=false
        return
    fi
    if [[ "$INTERACTIVE" == true ]]; then
        return
    fi
    if [[ -t 0 ]]; then
        INTERACTIVE=true
    fi
}

resolve_generation_mode() {
    local current_is_repo=false
    local script_parent_is_repo=false

    if is_repo_root "$CURRENT_DIR"; then
        current_is_repo=true
    fi
    if is_repo_root "$SCRIPT_DIR/.."; then
        script_parent_is_repo=true
    fi

    resolve_template_source

    if [[ "$PROJECT_NAME_SET" == true || "$MODULE_NAME_SET" == true ]]; then
        GENERATE_PROJECT=true
    elif [[ -n "$PROJECT_DIR" ]]; then
        if [[ -d "$PROJECT_DIR" && $(is_repo_root "$PROJECT_DIR"; printf "%s" "$?") -eq 0 ]]; then
            GENERATE_PROJECT=false
        else
            GENERATE_PROJECT=true
        fi
    elif [[ "$current_is_repo" == true || "$script_parent_is_repo" == true ]]; then
        GENERATE_PROJECT=false
    else
        GENERATE_PROJECT=true
    fi

    if [[ "$GENERATE_PROJECT" != true ]]; then
        return
    fi

    if [[ -z "$PROJECT_NAME" ]]; then
        if [[ -n "$PROJECT_DIR" ]]; then
            PROJECT_NAME="$(basename_from_path "$PROJECT_DIR")"
        else
            PROJECT_NAME="$TEMPLATE_PROJECT_NAME"
        fi
    fi

    if [[ "$INTERACTIVE" == true ]]; then
        PROJECT_NAME="$(ask_with_default "Project name" "$PROJECT_NAME")"
    fi
    validate_project_name "$PROJECT_NAME"

    if [[ -z "$MODULE_NAME" ]]; then
        MODULE_NAME="$PROJECT_NAME"
    fi
    if [[ "$INTERACTIVE" == true ]]; then
        MODULE_NAME="$(ask_with_default "Go module name" "$MODULE_NAME")"
    fi
    validate_module_name "$MODULE_NAME"

    local default_project_dir="$PROJECT_DIR"
    if [[ -z "$default_project_dir" ]]; then
        default_project_dir="$CURRENT_DIR/$PROJECT_NAME"
    fi
    if [[ "$INTERACTIVE" == true ]]; then
        PROJECT_DIR="$(ask_with_default "Project directory" "$default_project_dir")"
    elif [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$default_project_dir"
    fi

    apply_project_defaults
}

replace_in_files_cross_platform() {
    local old_pattern="$1"
    local new_replacement="$2"
    local project_dir="$3"

    local escaped_pattern
    local escaped_replacement
    escaped_pattern="$(escape_sed_pattern "$old_pattern")"
    escaped_replacement="$(escape_sed_replacement "$new_replacement")"

    local files_to_update=()
    while IFS= read -r -d '' file; do
        if grep -Fq -- "$old_pattern" "$file" 2>/dev/null; then
            files_to_update+=("$file")
        fi
    done < <(find "$project_dir" \
        \( -path "$project_dir/.git" -o -path "$project_dir/.git/*" -o -path "$project_dir/.github" -o -path "$project_dir/.github/*" \) -prune -o \
        -type f \( -name "*.go" -o -name "*.mod" -o -name "*.sum" -o -name "*.md" -o -name "*.MD" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" -o -name "*.default" -o -name "*.sh" -o -name "*.sql" -o -name ".gitignore" -o -name "Dockerfile" -o -name "Makefile" \) -print0 2>/dev/null || true)

    if [[ ${#files_to_update[@]} -eq 0 ]]; then
        return
    fi

    for file in "${files_to_update[@]}"; do
        local temp_file="${file}.tmp.$$"
        if sed "s|${escaped_pattern}|${escaped_replacement}|g" "$file" > "$temp_file" && mv "$temp_file" "$file"; then
            :
        else
            [[ -f "$temp_file" ]] && rm -f "$temp_file"
            print_error "Failed to update file: $file"
            exit 1
        fi
    done
}

rewrite_project_readme() {
    local readme_file="$PROJECT_DIR/README.md"
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] rewrite README.md"
        return
    fi

    cat > "$readme_file" <<EOF
# $PROJECT_NAME

A high-performance Go API project based on the dudu-admin-api framework. Built for rapid development of scalable backend services with enterprise-grade features.

## Description

This project provides a robust foundation for building RESTful APIs with Go, featuring:
- Clean architecture with layered design (Model-Repository-Service-Controller)
- Built-in dependency injection and configuration management
- Multi-database support (MySQL, MongoDB)
- JWT authentication and middleware system
- Internationalization (i18n) support
- High-performance logging with structured output
- Docker containerization support

## Features

- **High Performance**: Built on Gin framework for optimal performance
- **Clean Architecture**: Follows MVC + Repository pattern with proper separation of concerns
- **Configuration Management**: Environment-based configuration with JSON files
- **Authentication**: JWT-based authentication with middleware support
- **Multi-Database**: Support for MySQL and MongoDB with GORM and qmgo
- **Logging**: Structured logging with Zap for high performance
- **Internationalization**: Built-in i18n support for multiple languages
- **Task Scheduling**: Built-in job scheduler for background tasks
- **Message Queue**: Kafka consumer support for event-driven architecture
- **Docker Ready**: Complete Docker setup for development and production
- **Code Generation**: SQL-based code generation tools for rapid development

## Installation

### Prerequisites

- Go 1.24 or higher
- Git
- Make (optional, but recommended)
- Docker (optional, for containerized development)

### Setup

\`\`\`bash
git clone <your-repository-url>
cd $PROJECT_NAME
go mod download
\`\`\`

## Usage

### Development

\`\`\`bash
make run
# Or
go run main.go
\`\`\`

### Build

\`\`\`bash
make build
make docker-build
\`\`\`

### Test

\`\`\`bash
make test
go test -cover ./...
\`\`\`

## Configuration

Update configuration files in \`bin/configs/\` according to your environment.

## Project Structure

\`\`\`
$PROJECT_NAME/
├── app/
├── bootstrap/
├── bin/
│   ├── configs/
│   ├── data/
│   └── lang/
├── command/
├── scripts/
├── Dockerfile
├── Makefile
└── main.go
\`\`\`

## License

Please add your own LICENSE file for this project.

## Acknowledgments

- Built with [dudu-admin-api](https://github.com/seakee/dudu-admin-api) framework
- Powered by [Gin](https://gin-gonic.com/) web framework
- Database integration with [GORM](https://gorm.io/)
- Logging with [Zap](https://go.uber.org/zap)
EOF
}

cleanup_template_files() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] remove template git metadata and project docs"
        return
    fi

    local template_files=(
        ".git"
        ".github"
        ".gitignore.bak"
        "CONTRIBUTING.md"
        "CHANGELOG.md"
        "LICENSE"
    )

    for file in "${template_files[@]}"; do
        if [[ -e "$PROJECT_DIR/$file" ]]; then
            rm -rf "$PROJECT_DIR/$file"
        fi
    done
}

prepare_target_directory() {
    if [[ ! -e "$PROJECT_DIR" ]]; then
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] replace existing target path: $PROJECT_DIR"
        return
    fi

    if [[ "$YES" != true ]]; then
        if [[ "$INTERACTIVE" == true ]]; then
            print_warning "Target path already exists and will be removed: $PROJECT_DIR"
            if ! ask_yes_no "Remove it and continue?" "N"; then
                print_info "Cancelled."
                exit 0
            fi
        else
            print_error "Target path already exists: $PROJECT_DIR. Use --yes to replace it."
            exit 1
        fi
    fi

    rm -rf "$PROJECT_DIR"
}

clone_template_repository() {
    require_cmd git

    if [[ -z "$REPO_URL" ]]; then
        print_error "Template repository URL is empty. Provide --repo-url when the module name is not a remote repository path."
        exit 1
    fi

    if [[ "$SKIP_CLONE" == true ]]; then
        print_error "Project directory does not exist and --skip-clone is enabled: $PROJECT_DIR"
        print_error "Please clone template repository manually or remove --skip-clone."
        exit 1
    fi

    print_info "Cloning template repository into: $PROJECT_DIR"
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] git clone -b $REPO_REF --depth 1 $REPO_URL $PROJECT_DIR"
        return
    fi

    git clone -b "$REPO_REF" --depth 1 "$REPO_URL" "$PROJECT_DIR"
}

initialize_fresh_git_repository() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] initialize fresh git repository"
        return
    fi

    (
        cd "$PROJECT_DIR"
        git init >/dev/null
        git checkout -b main >/dev/null 2>&1 || true
        git add .
        git commit -m "Initial commit: Created $PROJECT_NAME from $TEMPLATE_PROJECT_NAME template" >/dev/null
    )
}

generate_project_from_template() {
    print_info "Generating project from template"
    print_info "Project name: $PROJECT_NAME"
    print_info "Module name: $MODULE_NAME"
    print_info "Target directory: $PROJECT_DIR"

    prepare_target_directory
    clone_template_repository

    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] replace template module and project references"
        print_info "[dry-run] cleanup template metadata and rewrite README"
        print_info "[dry-run] create fresh git repository"
        PROJECT_ROOT="$PROJECT_DIR"
        return
    fi

    cleanup_template_files

    replace_in_files_cross_platform "$TEMPLATE_MODULE_NAME" "$MODULE_NAME" "$PROJECT_DIR"
    if [[ "$PROJECT_NAME" != "$TEMPLATE_PROJECT_NAME" ]]; then
        replace_in_files_cross_platform "$TEMPLATE_PROJECT_NAME" "$PROJECT_NAME" "$PROJECT_DIR"
    fi

    rewrite_project_readme
    initialize_fresh_git_repository

    PROJECT_ROOT="$(cd "$PROJECT_DIR" && pwd)"
    print_success "Generated project repository: $PROJECT_ROOT"
}

prepare_project_root() {
    if [[ "$GENERATE_PROJECT" == true ]]; then
        generate_project_from_template
        return
    fi

    if [[ -n "$PROJECT_DIR" ]]; then
        if [[ ! -d "$PROJECT_DIR" ]]; then
            print_error "Project directory does not exist: $PROJECT_DIR"
            exit 1
        fi
        if ! is_repo_root "$PROJECT_DIR"; then
            print_error "Directory exists but is not a supported project repository: $PROJECT_DIR"
            exit 1
        fi
        PROJECT_ROOT="$(cd "$PROJECT_DIR" && pwd)"
        return
    fi

    if is_repo_root "$CURRENT_DIR"; then
        PROJECT_ROOT="$CURRENT_DIR"
        return
    fi

    if is_repo_root "$SCRIPT_DIR/.."; then
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
        return
    fi

    print_error "Unable to locate project repository. Provide --project-name to generate a new project or --project-dir to point to an existing one."
    exit 1
}

collect_inputs() {
    if [[ -n "$DIALECT" ]]; then
        DIALECT="$(printf "%s" "$DIALECT" | tr '[:upper:]' '[:lower:]')"
    fi
    if [[ "$DIALECT" != "mysql" && "$DIALECT" != "postgres" ]]; then
        DIALECT="postgres"
    fi

    if [[ -z "$DB_PORT" ]]; then
        if [[ "$DIALECT" == "mysql" ]]; then
            DB_PORT="3306"
        else
            DB_PORT="5432"
        fi
    fi

    if [[ -z "$SYSTEM_JWT_SECRET" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            SYSTEM_JWT_SECRET="DRY_RUN_SYSTEM_JWT_SECRET"
        else
            SYSTEM_JWT_SECRET="$(generate_secret 64)"
        fi
    fi
    if [[ -z "$ADMIN_JWT_SECRET" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            ADMIN_JWT_SECRET="DRY_RUN_ADMIN_JWT_SECRET"
        else
            ADMIN_JWT_SECRET="$(generate_secret 64)"
        fi
    fi

    if [[ "$INTERACTIVE" != true ]]; then
        return
    fi

    print_info "Starting interactive configuration wizard"
    RUN_ENV="$(ask_with_default "Runtime environment RUN_ENV" "$RUN_ENV")"
    SYSTEM_NAME="$(ask_with_default "system.name" "$SYSTEM_NAME")"
    SYSTEM_ROUTE_PREFIX="$(ask_with_default "system.route_prefix" "$SYSTEM_ROUTE_PREFIX")"
    SYSTEM_RUN_MODE="$(ask_with_default "system.run_mode (debug/release)" "$SYSTEM_RUN_MODE")"
    SYSTEM_HTTP_PORT="$(ask_with_default "system.http_port" "$SYSTEM_HTTP_PORT")"
    SYSTEM_DEFAULT_LANG="$(ask_with_default "system.default_lang" "$SYSTEM_DEFAULT_LANG")"

    local dialect_input
    dialect_input="$(ask_with_default "Database dialect (mysql/postgres)" "$DIALECT")"
    dialect_input="$(printf "%s" "$dialect_input" | tr '[:upper:]' '[:lower:]')"
    if [[ "$dialect_input" == "mysql" || "$dialect_input" == "postgres" ]]; then
        DIALECT="$dialect_input"
    fi

    local default_port="$DB_PORT"
    if [[ "$DIALECT" == "mysql" && "$default_port" != "3306" ]]; then
        default_port="3306"
    fi
    if [[ "$DIALECT" == "postgres" && "$default_port" != "5432" ]]; then
        default_port="5432"
    fi
    DB_HOST="$(ask_with_default "db_host" "$DB_HOST")"
    DB_PORT="$(ask_with_default "db_port" "$default_port")"
    DB_NAME="$(ask_with_default "db_name" "$DB_NAME")"
    DB_USER="$(ask_with_default "db_username" "$DB_USER")"
    DB_PASSWORD="$(ask_secret_with_default "db_password" "$DB_PASSWORD")"
    if [[ "$DIALECT" == "postgres" ]]; then
        DB_SSL_MODE="$(ask_with_default "ssl_mode" "$DB_SSL_MODE")"
        DB_TIMEZONE="$(ask_with_default "timezone" "$DB_TIMEZONE")"
    fi

    REDIS_HOST="$(ask_with_default "redis.host" "$REDIS_HOST")"
    REDIS_AUTH="$(ask_secret_with_default "redis.auth (optional)" "$REDIS_AUTH")"
    REDIS_DB="$(ask_with_default "redis.db" "$REDIS_DB")"

    if ask_yes_no "Override super admin (user_id=1) account fields?" "N"; then
        ADMIN_EMAIL="$(ask_with_default "admin email" "$ADMIN_EMAIL")"
        ADMIN_PHONE="$(ask_with_default "admin phone" "$ADMIN_PHONE")"
        ADMIN_USERNAME="$(ask_with_default "admin username" "$ADMIN_USERNAME")"
        ADMIN_PASSWORD="$(ask_secret_with_default "admin password (leave blank to keep unchanged)" "$ADMIN_PASSWORD")"
    fi
}

resolve_paths() {
    if [[ -z "$CONFIG_PATH" ]]; then
        CONFIG_PATH="$PROJECT_ROOT/bin/configs/${RUN_ENV}.json"
    fi
    if [[ -z "$SQL_FILE" ]]; then
        SQL_FILE="$PROJECT_ROOT/bin/data/sql/$DIALECT/init.sql"
    fi
}

write_config() {
    if [[ "$DRY_RUN" == true ]]; then
        print_info "[dry-run] write config to $CONFIG_PATH"
        return
    fi

    local tmp_go
    tmp_go="$(make_temp_go_file)"
    tmp_files+=("$tmp_go")

    cat > "$tmp_go" <<'EOF'
package main

import (
	"encoding/json"
	"os"
	"strconv"
)

type WebAuthn struct {
	RPID              string   `json:"rp_id"`
	RPDisplayName     string   `json:"rp_display_name"`
	RPOrigins         []string `json:"rp_origins"`
	ChallengeExpireIn int      `json:"challenge_expire_in"`
	UserVerification  string   `json:"user_verification"`
}

type Config struct {
	System struct {
		Name         string `json:"name"`
		RoutePrefix  string `json:"route_prefix"`
		RunMode      string `json:"run_mode"`
		HTTPPort     string `json:"http_port"`
		ReadTimeout  int    `json:"read_timeout"`
		WriteTimeout int    `json:"write_timeout"`
		Version      string `json:"version"`
		DebugMode    bool   `json:"debug_mode"`
		DefaultLang  string `json:"default_lang"`
		JwtSecret    string `json:"jwt_secret"`
		TokenExpire  int    `json:"token_expire"`
		Admin        struct {
			SafeCodeExpireIn int    `json:"safe_code_expire_in"`
			TokenExpireIn    int64  `json:"token_expire_in"`
			JwtSecret        string `json:"jwt_secret"`
			AuthRateLimit    struct {
				Enable        bool `json:"enable"`
				WindowSeconds int  `json:"window_seconds"`
				MaxRequests   int  `json:"max_requests"`
			} `json:"auth_rate_limit"`
			Oauth struct {
				RedirectURL string `json:"redirect_url"`
				Feishu      struct {
					ClientID     string `json:"client_id"`
					ClientSecret string `json:"client_secret"`
					OauthURL     string `json:"oauth_url"`
				} `json:"feishu"`
				Wechat struct {
					CorpID     string `json:"corp_id"`
					AgentID    string `json:"agent_id"`
					CorpSecret string `json:"corp_secret"`
					OauthURL   string `json:"oauth_url"`
					ProxyURL   string `json:"proxy_url"`
				} `json:"wechat"`
			} `json:"oauth"`
			WebAuthn WebAuthn `json:"webauthn"`
		} `json:"admin"`
	} `json:"system"`
	Log struct {
		Driver string `json:"driver"`
		Level  string `json:"level"`
		Path   string `json:"path"`
	} `json:"log"`
	Databases []map[string]any `json:"databases"`
	Cache     map[string]any   `json:"cache"`
	Redis     []map[string]any `json:"redis"`
	Kafka     map[string]any   `json:"kafka"`
	Monitor   map[string]any   `json:"monitor"`
	Notify    map[string]any   `json:"notify"`
}

func getenvInt(key string, def int) int {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

func getenvInt64(key string, def int64) int64 {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	n, err := strconv.ParseInt(v, 10, 64)
	if err != nil {
		return def
	}
	return n
}

func getenvBool(key string, def bool) bool {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	if v == "true" || v == "1" {
		return true
	}
	if v == "false" || v == "0" {
		return false
	}
	return def
}

func main() {
	outPath := os.Getenv("CFG_OUT_PATH")
	dialect := os.Getenv("CFG_DIALECT")
	projectIdentifier := os.Getenv("CFG_PROJECT_IDENTIFIER")
	if projectIdentifier == "" {
		projectIdentifier = os.Getenv("CFG_SYSTEM_NAME")
	}
	if projectIdentifier == "" {
		projectIdentifier = "app"
	}

	var cfg Config
	cfg.System.Name = os.Getenv("CFG_SYSTEM_NAME")
	cfg.System.RoutePrefix = os.Getenv("CFG_SYSTEM_ROUTE_PREFIX")
	cfg.System.RunMode = os.Getenv("CFG_SYSTEM_RUN_MODE")
	cfg.System.HTTPPort = os.Getenv("CFG_SYSTEM_HTTP_PORT")
	cfg.System.ReadTimeout = getenvInt("CFG_SYSTEM_READ_TIMEOUT", 60)
	cfg.System.WriteTimeout = getenvInt("CFG_SYSTEM_WRITE_TIMEOUT", 60)
	cfg.System.Version = os.Getenv("CFG_SYSTEM_VERSION")
	cfg.System.DebugMode = getenvBool("CFG_SYSTEM_DEBUG_MODE", false)
	cfg.System.DefaultLang = os.Getenv("CFG_SYSTEM_DEFAULT_LANG")
	cfg.System.JwtSecret = os.Getenv("CFG_SYSTEM_JWT_SECRET")
	cfg.System.TokenExpire = getenvInt("CFG_SYSTEM_TOKEN_EXPIRE", 604800)
	cfg.System.Admin.SafeCodeExpireIn = 180
	cfg.System.Admin.TokenExpireIn = getenvInt64("CFG_ADMIN_TOKEN_EXPIRE_IN", 2592000)
	cfg.System.Admin.JwtSecret = os.Getenv("CFG_ADMIN_JWT_SECRET")
	cfg.System.Admin.AuthRateLimit.Enable = true
	cfg.System.Admin.AuthRateLimit.WindowSeconds = 60
	cfg.System.Admin.AuthRateLimit.MaxRequests = 20
	cfg.System.Admin.Oauth.RedirectURL = "http://localhost:3000/auth/callback"
	cfg.System.Admin.Oauth.Feishu.OauthURL = "https://open.feishu.cn/open-apis/authen/v1/authorize"
	cfg.System.Admin.Oauth.Wechat.OauthURL = "https://open.weixin.qq.com/connect/oauth2/authorize"
	cfg.System.Admin.WebAuthn = WebAuthn{
		RPID:              "localhost",
		RPDisplayName:     cfg.System.Name,
		RPOrigins:         []string{"http://localhost:3000"},
		ChallengeExpireIn: 180,
		UserVerification:  "preferred",
	}

	cfg.Log.Driver = "stdout"
	cfg.Log.Level = "info"
	cfg.Log.Path = "storage/logs/"

	db := map[string]any{
		"enable":             true,
		"db_type":            dialect,
		"db_name":            os.Getenv("CFG_DB_NAME"),
		"db_host":            os.Getenv("CFG_DB_HOST"),
		"db_port":            getenvInt("CFG_DB_PORT", 0),
		"db_username":        os.Getenv("CFG_DB_USER"),
		"db_password":        os.Getenv("CFG_DB_PASSWORD"),
		"db_max_idle_conn":   10,
		"db_max_open_conn":   50,
		"conn_max_lifetime":  3,
		"conn_max_idle_time": 1,
	}
	if dialect == "mysql" {
		db["charset"] = "utf8mb4"
	} else if dialect == "postgres" {
		db["ssl_mode"] = os.Getenv("CFG_DB_SSL_MODE")
		db["timezone"] = os.Getenv("CFG_DB_TIMEZONE")
	}
	cfg.Databases = []map[string]any{
		db,
		{
			"enable":             false,
			"db_type":            "mongo",
			"db_name":            projectIdentifier,
			"db_host":            "mongodb://127.0.0.1:27017",
			"db_username":        projectIdentifier,
			"db_password":        "",
			"db_max_idle_conn":   10,
			"db_max_open_conn":   50,
			"auth_mechanism":     "SCRAM-SHA-1",
			"conn_max_lifetime":  1,
			"conn_max_idle_time": 1,
		},
	}

	cfg.Cache = map[string]any{
		"driver": "redis",
		"prefix": projectIdentifier,
	}

	cfg.Redis = []map[string]any{
		{
			"enable":       true,
			"name":         projectIdentifier,
			"host":         os.Getenv("CFG_REDIS_HOST"),
			"auth":         os.Getenv("CFG_REDIS_AUTH"),
			"max_idle":     30,
			"max_active":   100,
			"idle_timeout": 30,
			"prefix":       projectIdentifier,
			"db":           getenvInt("CFG_REDIS_DB", 0),
		},
	}

	cfg.Kafka = map[string]any{
		"brokers":              []string{},
		"max_retry":            1,
		"client_id":            projectIdentifier,
		"producer_enable":      false,
		"consumer_enable":      false,
		"consumer_group":       "",
		"consumer_topics":      []string{},
		"consumer_auto_submit": true,
	}

	cfg.Monitor = map[string]any{
		"panic_robot": map[string]any{
			"enable": false,
			"wechat": map[string]any{
				"enable":   false,
				"push_url": "",
			},
			"feishu": map[string]any{
				"enable":   false,
				"push_url": "",
			},
		},
	}

	cfg.Notify = map[string]any{
		"default_channel": "lark",
		"default_level":   "info",
		"lark": map[string]any{
			"enable":                    false,
			"default_send_channel_name": projectIdentifier,
			"channel_size":              0,
			"pool_size":                 0,
			"bot_webhooks":              map[string]string{},
			"larks":                     map[string]map[string]string{},
		},
	}

	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		os.Exit(1)
	}
	if err = os.WriteFile(outPath, append(data, '\n'), 0644); err != nil {
		os.Exit(1)
	}
}
EOF

    mkdir -p "$(dirname "$CONFIG_PATH")"

    CFG_OUT_PATH="$CONFIG_PATH" \
    CFG_DIALECT="$DIALECT" \
    CFG_PROJECT_IDENTIFIER="${PROJECT_NAME:-$SYSTEM_NAME}" \
    CFG_SYSTEM_NAME="$SYSTEM_NAME" \
    CFG_SYSTEM_ROUTE_PREFIX="$SYSTEM_ROUTE_PREFIX" \
    CFG_SYSTEM_RUN_MODE="$SYSTEM_RUN_MODE" \
    CFG_SYSTEM_HTTP_PORT="$SYSTEM_HTTP_PORT" \
    CFG_SYSTEM_READ_TIMEOUT="$SYSTEM_READ_TIMEOUT" \
    CFG_SYSTEM_WRITE_TIMEOUT="$SYSTEM_WRITE_TIMEOUT" \
    CFG_SYSTEM_VERSION="$SYSTEM_VERSION" \
    CFG_SYSTEM_DEBUG_MODE="$SYSTEM_DEBUG_MODE" \
    CFG_SYSTEM_DEFAULT_LANG="$SYSTEM_DEFAULT_LANG" \
    CFG_SYSTEM_JWT_SECRET="$SYSTEM_JWT_SECRET" \
    CFG_SYSTEM_TOKEN_EXPIRE="$SYSTEM_TOKEN_EXPIRE" \
    CFG_ADMIN_JWT_SECRET="$ADMIN_JWT_SECRET" \
    CFG_ADMIN_TOKEN_EXPIRE_IN="$ADMIN_TOKEN_EXPIRE_IN" \
    CFG_DB_HOST="$DB_HOST" \
    CFG_DB_PORT="$DB_PORT" \
    CFG_DB_NAME="$DB_NAME" \
    CFG_DB_USER="$DB_USER" \
    CFG_DB_PASSWORD="$DB_PASSWORD" \
    CFG_DB_SSL_MODE="$DB_SSL_MODE" \
    CFG_DB_TIMEZONE="$DB_TIMEZONE" \
    CFG_REDIS_HOST="$REDIS_HOST" \
    CFG_REDIS_AUTH="$REDIS_AUTH" \
    CFG_REDIS_DB="$REDIS_DB" \
    go run "$tmp_go"

    print_success "Config generated: $CONFIG_PATH"
}

confirm_destructive() {
    if [[ "$YES" == true || "$DRY_RUN" == true ]]; then
        return
    fi
    print_warning "About to execute init.sql. Related tables in database [$DB_NAME] will be reset (DROP TABLE)."
    if ! ask_yes_no "Continue?" "N"; then
        print_info "Cancelled."
        exit 0
    fi
}

create_database_if_needed() {
    if [[ "$CREATE_DB" != true ]]; then
        return
    fi
    print_info "Ensuring database exists: $DB_NAME"
    if [[ "$DIALECT" == "mysql" ]]; then
        local sql
        sql="CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] mysql create database"
        else
            mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" -e "$sql"
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] ensure postgres database exists: $DB_NAME"
        else
            if postgres_can_connect_db "$DB_NAME"; then
                print_info "Database already exists and is reachable: $DB_NAME"
            else
                local create_ok=false
                if command -v createdb >/dev/null 2>&1; then
                    if PGPASSWORD="$DB_PASSWORD" createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"; then
                        create_ok=true
                    fi
                else
                    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"$DB_NAME\";"; then
                        create_ok=true
                    fi
                fi

                if [[ "$create_ok" == true ]]; then
                    print_info "Created postgres database: $DB_NAME"
                elif postgres_can_connect_db "$DB_NAME"; then
                    print_info "Database became reachable: $DB_NAME"
                else
                    print_error "Failed to connect target postgres database '$DB_NAME' or create it automatically."
                    print_error "Ensure the database already exists and the user can connect to it, or grant CREATEDB / maintenance-database access."
                    exit 1
                fi
            fi
        fi
    fi
    print_success "Database check complete"
}

run_init_sql() {
    prepare_exec_sql_file
    print_info "Executing init SQL: $EXEC_SQL_FILE"
    if [[ "$DIALECT" == "mysql" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] mysql < $EXEC_SQL_FILE"
        else
            mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" < "$EXEC_SQL_FILE"
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] psql -f $EXEC_SQL_FILE"
        else
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -f "$EXEC_SQL_FILE"
        fi
    fi
    print_success "Init SQL executed successfully"
}

update_super_admin_if_needed() {
    if [[ -z "$ADMIN_EMAIL" && -z "$ADMIN_PHONE" && -z "$ADMIN_USERNAME" && -z "$ADMIN_PASSWORD" ]]; then
        return
    fi

    local sets=()
    if [[ -n "$ADMIN_EMAIL" ]]; then
        sets+=("email='$(escape_sql_string "$ADMIN_EMAIL")'")
    fi
    if [[ -n "$ADMIN_PHONE" ]]; then
        sets+=("phone='$(escape_sql_string "$ADMIN_PHONE")'")
    fi
    if [[ -n "$ADMIN_USERNAME" ]]; then
        sets+=("user_name='$(escape_sql_string "$ADMIN_USERNAME")'")
    fi
    if [[ -n "$ADMIN_PASSWORD" ]]; then
        print_info "Hashing super admin password as bcrypt(md5(password))"
        local pass_hash
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] hash super admin password with bcrypt(md5(password))"
            pass_hash="DRY_RUN_BCRYPT_MD5_PASSWORD"
        else
            pass_hash="$(hash_admin_password "$ADMIN_PASSWORD")"
        fi
        sets+=("password='$(escape_sql_string "$pass_hash")'")
        if [[ "$DIALECT" == "mysql" ]]; then
            sets+=("totp_enabled=0")
        else
            sets+=("totp_enabled=FALSE")
        fi
        sets+=("totp_key=NULL")
    fi

    local set_clause
    set_clause="$(IFS=, ; echo "${sets[*]}")"
    local sql=""

    if [[ "$DIALECT" == "mysql" ]]; then
        sql="UPDATE sys_user SET ${set_clause}, updated_at=NOW() WHERE id=1;"
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] update super admin (mysql)"
        else
            mysql --host="$DB_HOST" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" --database="$DB_NAME" -e "$sql"
        fi
    else
        sql="UPDATE sys_user SET ${set_clause}, updated_at=CURRENT_TIMESTAMP WHERE id=1;"
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] update super admin (postgres)"
        else
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -c "$sql"
        fi
    fi
    print_success "Super admin user(id=1) updated"
}

validate_inputs() {
    if [[ "$DIALECT" != "mysql" && "$DIALECT" != "postgres" ]]; then
        print_error "Invalid dialect: $DIALECT, only mysql/postgres are supported."
        exit 1
    fi
    if [[ -z "$DB_HOST" || -z "$DB_NAME" || -z "$DB_USER" ]]; then
        print_error "Incomplete DB config. db_host/db_name/db_user are required."
        exit 1
    fi
    if [[ -z "$SYSTEM_JWT_SECRET" || -z "$ADMIN_JWT_SECRET" ]]; then
        print_error "jwt_secret and admin.jwt_secret are required."
        exit 1
    fi
    if [[ -f "$CONFIG_PATH" && "$YES" != true && "$INTERACTIVE" != true && "$DRY_RUN" != true ]]; then
        print_error "Config already exists: $CONFIG_PATH. Use --yes to overwrite in non-interactive mode."
        exit 1
    fi
}

print_summary() {
    local effective_prefix
    effective_prefix="$(effective_route_prefix)"
    if [[ "$GENERATE_PROJECT" == true ]]; then
        print_info "Generate project: name=$PROJECT_NAME module=$MODULE_NAME dir=$PROJECT_DIR"
    fi
    print_info "Project root: $PROJECT_ROOT"
    print_info "Config path: $CONFIG_PATH"
    print_info "Dialect: $DIALECT"
    print_info "DB: $DB_NAME@$DB_HOST:$DB_PORT (user: $DB_USER)"
    print_info "Redis: $REDIS_HOST (db=$REDIS_DB)"
    print_info "System: name=$SYSTEM_NAME run_mode=$SYSTEM_RUN_MODE route_prefix=$SYSTEM_ROUTE_PREFIX effective_prefix=$effective_prefix"
}

main() {
    parse_args "$@"
    resolve_interactive_mode
    resolve_generation_mode

    require_cmd go
    prepare_project_root
    collect_inputs
    resolve_paths
    validate_inputs
    print_summary

    if [[ "$INTERACTIVE" == true && "$DRY_RUN" != true ]]; then
        if ! ask_yes_no "Write the config and run initialization?" "Y"; then
            print_info "Cancelled."
            exit 0
        fi
    fi

    if [[ "$DIALECT" == "mysql" ]]; then
        if [[ "$DRY_RUN" != true ]]; then
            require_cmd mysql
        fi
        [[ -z "$DB_PORT" ]] && DB_PORT="3306"
    else
        if [[ "$DRY_RUN" != true ]]; then
            require_cmd psql
        fi
        [[ -z "$DB_PORT" ]] && DB_PORT="5432"
    fi

    write_config

    if [[ "$SKIP_GO_MOD" != true ]]; then
        print_info "Downloading Go modules"
        if [[ "$DRY_RUN" == true ]]; then
            print_info "[dry-run] (cd $PROJECT_ROOT && go mod download)"
        else
            (cd "$PROJECT_ROOT" && go mod download)
        fi
    fi

    confirm_destructive
    create_database_if_needed
    run_init_sql
    update_super_admin_if_needed

    print_success "Project initialization completed"
    if [[ "$CONFIG_PATH" == "$PROJECT_ROOT/bin/configs/${RUN_ENV}.json" ]]; then
        print_info "Run with: cd $PROJECT_ROOT && RUN_ENV=$RUN_ENV make run"
    else
        print_info "Run with: cd $PROJECT_ROOT && APP_CONFIG_PATH=$CONFIG_PATH make run"
    fi
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
    main "$@"
fi
