#!/bin/bash
# goVLESS bootstrap — one-liner installer
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/Glazzeg/goVLESS_v1/main/bootstrap.sh)
set -euo pipefail

# Keep Git from prompting for credentials in non-interactive installs.
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/bin/false

# The repository is public. Optional overrides support private forks.
REPO="${GOVLESS_REPO:-https://github.com/Glazzeg/goVLESS_v1.git}"
BRANCH="${GOVLESS_BRANCH:-main}"
INSTALL_DIR="/opt/govless-installer"
# Canonical URL (no token) — for error messages and final remote
REPO_CANONICAL="$REPO"

# Build auth args for git: use Authorization header (NEVER put token in URL,
# git would persist it into .git/config and leak via stderr on failure).
GIT_AUTH_ARGS=()
if [ -n "${GH_TOKEN:-}" ] && [[ "$REPO" == https://github.com/* ]] && [[ "$REPO" != *"@"* ]]; then
    AUTH_B64=$(printf "x-access-token:%s" "$GH_TOKEN" | base64 -w0)
    GIT_AUTH_ARGS=(-c "http.${REPO}.extraHeader=Authorization: Basic $AUTH_B64")
fi

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

echo ""
echo -e "  ${CYAN}${BOLD}goVLESS Installer${NC}"
echo -e "  ${CYAN}─────────────────${NC}"
echo ""

# Root check
if [ "$(id -u)" -ne 0 ]; then
    echo -e "  ${RED}✗${NC} Run as root: ${BOLD}sudo bash bootstrap.sh${NC}"
    exit 1
fi

# Install git if missing
if ! command -v git &>/dev/null; then
    echo -e "  ${CYAN}ℹ${NC}  Installing git..."
    apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq git >/dev/null 2>&1
fi

# Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e "  ${CYAN}ℹ${NC}  Updating..."
    cd "$INSTALL_DIR"
    if git "${GIT_AUTH_ARGS[@]}" fetch origin "$BRANCH" --quiet 2>/dev/null; then
        # fail-soft: a dirty/divergent working copy must NOT abort the
        # script under `set -e` before we exec the installer. Force-checkout;
        # if any step fails, keep going and run whatever local copy exists.
        git checkout -f "$BRANCH" --quiet 2>/dev/null \
            || git checkout -qB "$BRANCH" "origin/$BRANCH" 2>/dev/null || true
        git reset --hard "origin/$BRANCH" --quiet 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC}  Updated to latest $BRANCH"
    else
        echo -e "  ${CYAN}ℹ${NC}  Could not update from $REPO — continuing with the installed copy."
        echo -e "  ${CYAN}ℹ${NC}  Check the repository URL, branch, and network before updating."
    fi
else
    echo -e "  ${CYAN}ℹ${NC}  Downloading goVLESS..."
    if [ -e "$INSTALL_DIR" ]; then
        echo -e "  ${RED}✗${NC} $INSTALL_DIR exists but is not a Git checkout."
        echo -e "  ${RED}✗${NC} Move or rename it, then run the installer again."
        exit 1
    fi
    if ! git "${GIT_AUTH_ARGS[@]}" clone -b "$BRANCH" --depth 1 "$REPO_CANONICAL" "$INSTALL_DIR" 2>/dev/null; then
        echo -e "  ${RED}✗${NC} Failed to clone $REPO_CANONICAL (branch $BRANCH)"
        echo -e "  ${RED}✗${NC} Check the repository URL, branch, and network connection."
        exit 1
    fi
fi

if [ ! -f "$INSTALL_DIR/govless.sh" ]; then
    echo -e "  ${RED}✗${NC} Download failed"
    exit 1
fi

echo -e "  ${GREEN}✓${NC}  Ready"
echo ""

# Run
cd "$INSTALL_DIR"
# curl|bash puts THIS script on stdin; reconnect the child's stdin to the
# controlling terminal (when one exists) IN the exec so govless.sh prompts read
# keystrokes. Detached/non-interactive runs (no /dev/tty) keep piped stdin.
if [ ! -t 0 ] && [ -r /dev/tty ]; then
    exec bash govless.sh "$@" < /dev/tty
else
    exec bash govless.sh "$@"
fi
