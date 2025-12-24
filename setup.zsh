#!/usr/bin/env zsh
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$DOTFILES_DIR/backup"

mkdir -p "$BACKUP_DIR"

# -------------------------
# helpers
# -------------------------
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

confirm() {
  local prompt="$1"
  read -r "?$prompt [Y/n]: " answer
  [[ "$answer" == "" || "$answer" == "Y" || "$answer" == "y" ]]
}

warn() { echo "⚠️  $1"; }
info() { echo "ℹ️  $1"; }
error() { echo "❌ $1"; }

# -------------------------
# OS check
# -------------------------
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
  error "This setup script only supports Linux."
  exit 1
fi

info "Linux detected."

# -------------------------
# tools & links
# -------------------------
declare -A TOOLS
TOOLS=(
  [zsh]="https://www.zsh.org/"
  [starship]="https://starship.rs/install/"
  [nvim]="https://github.com/neovim/neovim/releases/latest"
  [tmux]="https://github.com/tmux/tmux/wiki/Installing"
  [git]="https://git-scm.com/downloads"
  [kitty]="https://sw.kovidgoyal.net/kitty/binary/"
  [stow]="https://www.gnu.org/software/stow/"
)

INSTALLED_TOOLS=()
MISSING_TOOLS=()

for tool link in ${(kv)TOOLS}; do
  if command_exists "$tool"; then
    info "$tool is installed."
    INSTALLED_TOOLS+=("$tool")
  else
    warn "$tool is NOT installed."
    echo "    → Install from: $link"
    MISSING_TOOLS+=("$tool")
  fi
done

echo "make sure to backup your config before continuing"
  if ! confirm "do you want to continue"; then
    error "Aborted by user."
    exit 1
  fi

# -------------------------
# stow
# -------------------------
if ! command_exists stow; then
  warn "stow is not installed. Skipping symlink step."
  echo "    → Install from: ${TOOLS[stow]}"
  exit 0
fi

cd "$DOTFILES_DIR"

STOWED_TOOLS=()
SKIPPED_TOOLS=()

for tool in "${INSTALLED_TOOLS[@]}"; do
  if [[ -d "$DOTFILES_DIR/$tool" ]]; then
    if confirm "Apply $tool configuration?"; then
      stow "$tool"
      STOWED_TOOLS+=("$tool")
    else
      SKIPPED_TOOLS+=("$tool")
    fi
  fi
done

  echo "\ntools configured"
for tool in "${STOWED_TOOLS[@]}"; do
  echo "$tool"
done
echo "\ntools skipped"
for tool in "${SKIPPED_TOOLS[@]}"; do
  echo "$tool"
done
echo "✅ Setup complete."

