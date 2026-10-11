#!/usr/bin/env bash
# bootstrap.sh — install dotfiles from GitHub with a single command.
#
#   curl -fsSL https://raw.githubusercontent.com/mame7743/dotfiles/master/bootstrap.sh | bash
#
# Options (pass after `bash -s --`):
#   --deps       also install dependencies (scripts/install-deps.sh)
#   --deps-core  install only the minimal applications (scripts/install-deps.sh --core)
set -euo pipefail

REPO_URL="https://github.com/mame7743/dotfiles.git"
BRANCH="master"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
INSTALL_DEPS=0
DEPS_ARGS=()

info()  { printf '\033[0;34m[info]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[ok]\033[0m    %s\n' "$*"; }
warn()  { printf '\033[0;33m[warn]\033[0m  %s\n' "$*"; }
error() { printf '\033[0;31m[error]\033[0m %s\n' "$*" >&2; }

for arg in "$@"; do
  case "$arg" in
    --deps)      INSTALL_DEPS=1 ;;
    --deps-core) INSTALL_DEPS=1; DEPS_ARGS=(--core) ;;
    *) warn "Unknown argument: $arg" ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  error "git is required. Install it first (brew install git / apt install git)."
  exit 1
fi

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "Updating existing repo at $DOTFILES_DIR"
  if ! git -C "$DOTFILES_DIR" diff --quiet HEAD; then
    warn "$DOTFILES_DIR has uncommitted changes — skipping update, keeping local state."
  else
    git -C "$DOTFILES_DIR" fetch origin --prune
    git -C "$DOTFILES_DIR" checkout -B "$BRANCH" "origin/$BRANCH"
  fi
else
  info "Cloning dotfiles into $DOTFILES_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$DOTFILES_DIR"
fi

# --- Submodules (agent-skills など) ------------------------------------------
# ワンライナーだけで完結させるため、ここで自動的に初期化する。
# 1つ失敗しても巻き添えで他が未取得にならないよう、パスごとに更新する。
if [[ -f "$DOTFILES_DIR/.gitmodules" ]]; then
  info "Updating git submodules"
  submodule_paths="$(git -C "$DOTFILES_DIR" config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}')"
  if [[ -z "$submodule_paths" ]]; then
    warn "submodule の定義を読み取れませんでした（$DOTFILES_DIR/.gitmodules）"
  else
    failed_submodules=()
    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      if git -C "$DOTFILES_DIR" submodule update --init --recursive -- "$path"; then
        success "submodule: $path"
      else
        failed_submodules+=("$path")
      fi
    done <<< "$submodule_paths"
    if [[ ${#failed_submodules[@]} -gt 0 ]]; then
      warn "取得できなかった submodule: ${failed_submodules[*]}"
      warn "  → 非公開リポジトリは認証が必要です（例: gh auth login）"
    fi
  fi
fi

info "Linking dotfiles"
bash "$DOTFILES_DIR/scripts/install.sh"

if [[ "$INSTALL_DEPS" == "1" ]]; then
  info "Installing dependencies"
  bash "$DOTFILES_DIR/scripts/install-deps.sh" ${DEPS_ARGS[@]+"${DEPS_ARGS[@]}"}
fi

success "Done! Open a new shell to apply changes."