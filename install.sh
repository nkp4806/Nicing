#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "       NEET CRIMSON RICE INSTALLER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

copy_file() {
    local src="$1"
    local dst="$2"

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

# ─────────────────────────────────────────────
# Basic dependency checks
# ─────────────────────────────────────────────

echo "Checking dependencies..."

missing=()

command_exists gsettings || missing+=("gsettings")
command_exists gnome-extensions || missing+=("gnome-extensions")
command_exists gnome-terminal || missing+=("gnome-terminal")
command_exists systemctl || missing+=("systemctl")

if ((${#missing[@]})); then
    echo
    echo "Missing required commands:"
    printf '  - %s\n' "${missing[@]}"
    echo
    echo "Install the missing GNOME components first."
    exit 1
fi

echo "✓ Basic GNOME dependencies found"

# ─────────────────────────────────────────────
# Create directories
# ─────────────────────────────────────────────

mkdir -p \
    "$HOME_DIR/.config/neet-themes" \
    "$HOME_DIR/.config/fastfetch" \
    "$HOME_DIR/.config/btop/themes" \
    "$HOME_DIR/.config/systemd/user" \
    "$HOME_DIR/.local/bin" \
    "$HOME_DIR/.local/share/gnome-shell/extensions"

# ─────────────────────────────────────────────
# Theme files
# ─────────────────────────────────────────────

echo "Installing Neet Crimson theme..."

rm -rf "$HOME_DIR/.config/neet-themes/crimson"
cp -a "$REPO_DIR/config/neet-themes/crimson" \
      "$HOME_DIR/.config/neet-themes/crimson"

echo "✓ Theme configuration"

# ─────────────────────────────────────────────
# Theme switcher
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/local-bin/neet-theme" \
    "$HOME_DIR/.local/bin/neet-theme"

chmod +x "$HOME_DIR/.local/bin/neet-theme"

echo "✓ Theme switcher"

# ─────────────────────────────────────────────
# CPU tools
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/local-bin/neet-cpu-sampler.sh" \
    "$HOME_DIR/.local/bin/neet-cpu-sampler.sh"

copy_file \
    "$REPO_DIR/local-bin/neet-cpu-display.sh" \
    "$HOME_DIR/.local/bin/neet-cpu-display.sh"

copy_file \
    "$REPO_DIR/local-bin/neet-metrics.sh" \
    "$HOME_DIR/.local/bin/neet-metrics.sh"

chmod +x \
    "$HOME_DIR/.local/bin/neet-cpu-sampler.sh" \
    "$HOME_DIR/.local/bin/neet-cpu-display.sh" \
    "$HOME_DIR/.local/bin/neet-metrics.sh"

echo "✓ CPU / metrics scripts"

# ─────────────────────────────────────────────
# CPU sampler service
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/config/systemd/user/neet-cpu-sampler.service" \
    "$HOME_DIR/.config/systemd/user/neet-cpu-sampler.service"

systemctl --user daemon-reload
systemctl --user enable --now neet-cpu-sampler.service

echo "✓ CPU sampler service"

# ─────────────────────────────────────────────
# Fastfetch
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/config/fastfetch/config.jsonc" \
    "$HOME_DIR/.config/fastfetch/config.jsonc"

copy_file \
    "$REPO_DIR/config/fastfetch/neet.txt" \
    "$HOME_DIR/.config/fastfetch/neet.txt"

copy_file \
    "$REPO_DIR/config/fastfetch/resource-bar.sh" \
    "$HOME_DIR/.config/fastfetch/resource-bar.sh"

chmod +x "$HOME_DIR/.config/fastfetch/resource-bar.sh"

echo "✓ Fastfetch"

# ─────────────────────────────────────────────
# btop
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/config/btop/btop.conf" \
    "$HOME_DIR/.config/btop/btop.conf"

copy_file \
    "$REPO_DIR/config/btop/themes/NEET.theme" \
    "$HOME_DIR/.config/btop/themes/NEET.theme"

echo "✓ btop"

# ─────────────────────────────────────────────
# Neet Papirus icons
# ─────────────────────────────────────────────

ICON_THEME_DIR="$HOME_DIR/.icons/Neet-Papirus"

mkdir -p "$HOME_DIR/.icons"
rm -rf "$ICON_THEME_DIR"
cp -a \
    "$REPO_DIR/config/icons/Neet-Papirus" \
    "$ICON_THEME_DIR"

echo "✓ Neet Papirus icons"

# ─────────────────────────────────────────────
# GTK
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/config/gtk-3.0/gtk.css" \
    "$HOME_DIR/.config/gtk-3.0/gtk.css"

copy_file \
    "$REPO_DIR/config/gtk-4.0/gtk.css" \
    "$HOME_DIR/.config/gtk-4.0/gtk.css"

echo "✓ GTK"

# ─────────────────────────────────────────────
# GNOME Shell theme
# ─────────────────────────────────────────────

mkdir -p "$HOME_DIR/.themes/Colloid-Crimson/gnome-shell"

copy_file \
    "$REPO_DIR/gnome-shell/gnome-shell.css" \
    "$HOME_DIR/.themes/Colloid-Crimson/gnome-shell/gnome-shell.css"

echo "✓ GNOME Shell theme"

# ─────────────────────────────────────────────
# Neet Metrics extension
# ─────────────────────────────────────────────

METRICS_DIR="$HOME_DIR/.local/share/gnome-shell/extensions/neet-metrics@local"

rm -rf "$METRICS_DIR"
cp -a \
    "$REPO_DIR/extensions/neet-metrics@local" \
    "$METRICS_DIR"

echo "✓ Neet Metrics extension"

if command_exists gnome-extensions; then
    gnome-extensions enable neet-metrics@local 2>/dev/null || true
fi

# ─────────────────────────────────────────────
# Bash prompt
# ─────────────────────────────────────────────

copy_file \
    "$REPO_DIR/config/neet-theme-prompt.sh" \
    "$HOME_DIR/.config/neet-theme-prompt.sh"

echo "✓ Bash prompt"

# ─────────────────────────────────────────────
# Bash integration
# ─────────────────────────────────────────────

BASHRC="$HOME_DIR/.bashrc"
BASH_MARKER="# >>> NEET RICE >>>"
LEGACY_MARKER="# NEET RICE — custom Bash prompt"

if [[ ! -f "$BASHRC" ]]; then
    touch "$BASHRC"
fi

if grep -Fq "$BASH_MARKER" "$BASHRC"; then
    echo "✓ Bash integration already present"
elif grep -Fq "$LEGACY_MARKER" "$BASHRC"; then
    echo "✓ Existing Neet Bash integration detected"
else
    cat >> "$BASHRC" <<'BASH_BLOCK'

# >>> NEET RICE >>>
export PATH="$HOME/.local/bin:$PATH"

if [[ $- == *i* ]] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

if [[ -f "$HOME/.config/neet-theme-prompt.sh" ]]; then
    source "$HOME/.config/neet-theme-prompt.sh"
fi

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
# <<< NEET RICE <<<
BASH_BLOCK

    echo "✓ Bash integration added"
fi

# ─────────────────────────────────────────────
# Wallpaper
# ─────────────────────────────────────────────

if [[ -f "$REPO_DIR/wallpaper/griffith-crimson.bmp" ]]; then
    mkdir -p "$HOME_DIR/Pictures/Wallpapers"

    copy_file \
        "$REPO_DIR/wallpaper/griffith-crimson.bmp" \
        "$HOME_DIR/Pictures/Wallpapers/griffith-crimson.bmp"

    echo "✓ Wallpaper"
fi

# ─────────────────────────────────────────────
# Apply Crimson
# ─────────────────────────────────────────────

echo
echo "Applying Neet Crimson..."

"$HOME_DIR/.local/bin/neet-theme" crimson

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Neet Crimson installation complete."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Open a new terminal to load the shell prompt."
echo "A GNOME Shell restart/logout may be required for"
echo "some shell extensions and theme changes."
