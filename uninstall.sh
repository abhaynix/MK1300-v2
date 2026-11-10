#!/usr/bin/env bash
# Keyboard Studio: uninstaller. Removes what install.sh put in place.
#
# Usage:
#   ./uninstall.sh            remove app, launcher, icon and udev rule
#   ./uninstall.sh --purge    also remove the per-user config directory
#
# Environment:
#   PREFIX=DIR     must match the PREFIX used at install time (default: $HOME/.local)
#   KEEP_UDEV=1    leave the system udev rule in place
set -euo pipefail

APP_ID="dev.exdevx.keyboard_studio"
CMD_NAME="keyboard-studio"
PREFIX="${PREFIX:-$HOME/.local}"
KEEP_UDEV="${KEEP_UDEV:-0}"
PURGE=0
for arg in "$@"; do
    case "$arg" in
        --purge) PURGE=1 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "[error] unknown option: $arg" >&2; exit 2 ;;
    esac
done

APP_DIR="${PREFIX}/share/${CMD_NAME}"
BIN_LINK="${PREFIX}/bin/${CMD_NAME}"
DESKTOP_FILE="${PREFIX}/share/applications/${APP_ID}.desktop"
ICON_FILE="${PREFIX}/share/icons/hicolor/512x512/apps/${APP_ID}.png"
UDEV_DEST="/etc/udev/rules.d/99-keyboard-studio-mk1300.rules"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/keyboard-studio"

info() { printf '[info]  %s\n' "$*"; }
warn() { printf '[warn]  %s\n' "$*" >&2; }

remove_path() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        rm -rf -- "$1"
        info "removed $1"
    fi
}

main() {
    remove_path "$BIN_LINK"
    remove_path "$APP_DIR"
    remove_path "$DESKTOP_FILE"
    remove_path "$ICON_FILE"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${PREFIX}/share/applications" >/dev/null 2>&1 || true
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -q -t "${PREFIX}/share/icons/hicolor" >/dev/null 2>&1 || true
    fi

    if [ "$KEEP_UDEV" = "1" ]; then
        info "KEEP_UDEV=1: udev rule left in place"
    elif [ -f "$UDEV_DEST" ]; then
        local sudo_cmd=""
        if [ "$(id -u)" -ne 0 ]; then
            command -v sudo >/dev/null 2>&1 || { warn "sudo not found; remove $UDEV_DEST manually"; sudo_cmd="__skip__"; }
            [ "$sudo_cmd" = "__skip__" ] || sudo_cmd="sudo"
        fi
        if [ "$sudo_cmd" != "__skip__" ]; then
            $sudo_cmd rm -f -- "$UDEV_DEST"
            $sudo_cmd udevadm control --reload-rules
            $sudo_cmd udevadm trigger
            info "removed $UDEV_DEST and reloaded udev"
        fi
    else
        info "no udev rule found at $UDEV_DEST"
    fi

    if [ "$PURGE" = "1" ]; then
        remove_path "$CONFIG_DIR"
    else
        info "config kept at $CONFIG_DIR (use --purge to delete it)"
    fi

    info "${CMD_NAME} uninstalled"
}

main "$@"
