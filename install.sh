#!/bin/bash
#
# Makepad Skills Installer
# https://github.com/project-robius/makepad-skills
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash -s -- --with-hooks
#   curl -fsSL https://raw.githubusercontent.com/project-robius/makepad-skills/main/install.sh | bash -s -- --target /path/to/project
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPO_URL="https://github.com/project-robius/makepad-skills"
BRANCH="main"
TARGET_DIR=""
WITH_HOOKS=false
TEMP_DIR=""

# Print colored message
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Print banner
print_banner() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}      ${GREEN}Makepad Skills Installer v2.1.0${NC}         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}      Claude Code Skills for Makepad          ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --target DIR      Install to specific directory (default: current directory)"
    echo "  --with-hooks      Also install and configure hooks"
    echo "  --branch BRANCH   Use specific branch (default: main)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Install to current project"
    echo "  $0"
    echo ""
    echo "  # Install with hooks enabled"
    echo "  $0 --with-hooks"
    echo ""
    echo "  # Install to specific project"
    echo "  $0 --target /path/to/my-makepad-project"
    echo ""
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TARGET_DIR="$2"
                shift 2
                ;;
            --with-hooks)
                WITH_HOOKS=true
                shift
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Check dependencies
check_deps() {
    info "Checking dependencies..."

    if ! command -v git &> /dev/null; then
        error "git is required but not installed. Please install git first."
    fi

    success "Dependencies OK"
}

# Determine target directory
determine_target() {
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="$(pwd)"
    fi

    # Expand to absolute path
    TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || error "Target directory does not exist: $TARGET_DIR"

    info "Target directory: $TARGET_DIR"

    # Check if it looks like a project directory
    if [[ ! -f "$TARGET_DIR/Cargo.toml" ]]; then
        warn "No Cargo.toml found. This may not be a Rust/Makepad project."
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Clone or download repository
download_skills() {
    info "Downloading makepad-skills..."

    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TEMP_DIR/makepad-skills" 2>/dev/null || \
        error "Failed to clone repository. Check your internet connection."

    success "Downloaded successfully"
}

# Install skills
install_skills() {
    local SKILLS_DIR="$TARGET_DIR/.claude/skills"

    info "Installing skills to $SKILLS_DIR..."

    # Create .claude directory if needed
    mkdir -p "$TARGET_DIR/.claude"

    # Backup existing skills if present
    if [[ -d "$SKILLS_DIR" ]]; then
        local BACKUP_DIR="$SKILLS_DIR.backup.$(date +%Y%m%d%H%M%S)"
        warn "Existing skills found. Backing up to $BACKUP_DIR"
        mv "$SKILLS_DIR" "$BACKUP_DIR"
    fi

    # Copy skills
    cp -r "$TEMP_DIR/makepad-skills/skills" "$SKILLS_DIR"

    success "Skills installed"
}

# Install hooks
install_hooks() {
    if [[ "$WITH_HOOKS" != true ]]; then
        return
    fi

    local SKILLS_DIR="$TARGET_DIR/.claude/skills"
    local HOOKS_SRC="$SKILLS_DIR/99-evolution/hooks"
    local HOOKS_DST="$SKILLS_DIR/hooks"

    info "Installing hooks..."

    if [[ -d "$HOOKS_SRC" ]]; then
        cp -r "$HOOKS_SRC" "$HOOKS_DST"
        chmod +x "$HOOKS_DST"/*.sh
        success "Hooks installed to $HOOKS_DST"

        echo ""
        warn "To enable hooks, add the following to your .claude/settings.json:"
        echo ""
        echo -e "${YELLOW}$(cat "$HOOKS_SRC/settings.example.json")${NC}"
        echo ""
    else
        warn "Hooks source not found, skipping"
    fi
}

# Print summary
print_summary() {
    local SKILLS_DIR="$TARGET_DIR/.claude/skills"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Skills installed to: $SKILLS_DIR"
    echo ""
    echo "  Structure:"
    echo "  ├── 00-getting-started/  (Project setup)"
    echo "  ├── 01-core/             (Layout, widgets, events)"
    echo "  ├── 02-components/       (Widget gallery)"
    echo "  ├── 03-graphics/         (Shaders, animations)"
    echo "  │   ├── _base/           (Official skills)"
    echo "  │   └── community/       (Your contributions)"
    echo "  ├── 04-patterns/         (Production patterns)"
    echo "  │   ├── _base/           (Official patterns)"
    echo "  │   └── community/       (Your contributions)"
    echo "  ├── 05-deployment/       (Build & package)"
    echo "  ├── 06-reference/        (Troubleshooting)"
    echo "  └── 99-evolution/        (Self-improvement)"
    echo ""
    echo "  Quick Start:"
    echo "  1. Open your project with Claude Code"
    echo "  2. Ask: \"Create a simple Makepad counter app\""
    echo ""
    if [[ "$WITH_HOOKS" == true ]]; then
        echo -e "  ${YELLOW}Hooks are installed but need manual configuration.${NC}"
        echo "  See the settings.json snippet above."
        echo ""
    else
        echo "  To enable auto-evolution hooks:"
        echo "  $0 --with-hooks --target $TARGET_DIR"
        echo ""
    fi
    echo "  Documentation: https://github.com/project-robius/makepad-skills"
    echo ""
}

# Main
main() {
    print_banner
    parse_args "$@"
    check_deps
    determine_target
    download_skills
    install_skills
    install_hooks
    print_summary
}

main "$@"
