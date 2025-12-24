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

# -------------------------
# config paths
# -------------------------
declare -A CONFIG_PATHS
CONFIG_PATHS=(
  [zsh]="$HOME/.zshrc"
  [nvim]="$HOME/.config/nvim"
  [tmux]="$HOME/.tmux.conf"
  [kitty]="$HOME/.config/kitty"
  [starship]="$HOME/.config/starship.toml"
  [git]="$HOME/.gitconfig"
)

# -------------------------
# backup existing configs
# -------------------------
FOUND_CONFIGS=()

for tool in $INSTALLED_TOOLS; do
  path="${CONFIG_PATHS[$tool]}"
  [[ -n "$path" && -e "$path" ]] && FOUND_CONFIGS+=("$tool:$path")
done

if (( ${#FOUND_CONFIGS[@]} > 0 )); then
  warn "Existing configuration files detected:"
  for item in $FOUND_CONFIGS; do
    echo "   - ${item#*:}"
  done

  if ! confirm "Backup existing configs and continue?"; then
    error "Aborted by user."
    exit 1
  fi

  for item in $FOUND_CONFIGS; do
    tool="${item%%:*}"
    path="${item#*:}"

    if [[ "$tool" == "git" ]]; then
      if confirm "Copy existing git config?"; then
        cp "$path" "$BACKUP_DIR/gitconfig.backup"
        info "Git config backed up."
      else
        info "Skipped git config backup."
      fi
      continue
    fi

    mv "$path" "$BACKUP_DIR/$(basename "$path").backup"
    info "Backed up $path"
  done
fi

# -------------------------
# stow
# -------------------------
if ! command_exists stow; then
  warn "stow is not installed. Skipping symlink step."
  echo "    → Install from: ${TOOLS[stow]}"
  exit 0
fi

STOW_TARGETS=()

for tool in $INSTALLED_TOOLS; do
  [[ -d "$DOTFILES_DIR/$tool" ]] && STOW_TARGETS+=("$tool")
done

if (( ${#STOW_TARGETS[@]} == 0 )); then
  warn "No stowable directories found."
  exit 0
fi

cd "$DOTFILES_DIR"

info "Ready to stow: ${STOW_TARGETS[*]}"

if confirm "Proceed with stow?"; then
  stow "${STOW_TARGETS[@]}"
  info "Dotfiles successfully stowed."
else
  warn "Stow skipped."
fi

echo "✅ Setup complete (partial installs allowed)."

