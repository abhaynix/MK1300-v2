#!/usr/bin/env bash
# Keyboard Studio: user-level installer.
#
# Installs the AppImage for the current user, a launcher entry and icon, and
# (unless SKIP_UDEV=1) the udev rule that lets non-root users reach the
# MK1300 V2 keyboard over hidraw. The udev step uses sudo.
#
# Usage:
#   ./install.sh [path/to/KeyboardStudio-x86_64.AppImage]
#
# Environment:
#   PREFIX=DIR    user install prefix (default: $HOME/.local)
#   SKIP_UDEV=1   do not install the udev rule (no sudo, keyboard needs root)
#
# Read it before running. It only writes under $PREFIX and, when enabled,
# /etc/udev/rules.d/99-keyboard-studio-mk1300.rules.
set -euo pipefail

APP_NAME="Keyboard Studio"
APP_ID="dev.exdevx.keyboard_studio"
CMD_NAME="keyboard-studio"
PREFIX="${PREFIX:-$HOME/.local}"
SKIP_UDEV="${SKIP_UDEV:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${PREFIX}/share/${CMD_NAME}"
BIN_LINK="${PREFIX}/bin/${CMD_NAME}"
DESKTOP_FILE="${PREFIX}/share/applications/${APP_ID}.desktop"
ICON_FILE="${PREFIX}/share/icons/hicolor/512x512/apps/${APP_ID}.png"
UDEV_DEST="/etc/udev/rules.d/99-keyboard-studio-mk1300.rules"

info() { printf '[info]  %s\n' "$*"; }
warn() { printf '[warn]  %s\n' "$*" >&2; }
fail() { printf '[error] %s\n' "$*" >&2; exit 1; }
trap 'printf "[error] install stopped at line %s. Nothing else was changed; run uninstall.sh to clean up partial files.\n" "$LINENO" >&2' ERR

find_first() {
    local candidate
    for candidate in "$@"; do
        if [ -f "$candidate" ]; then printf '%s\n' "$candidate"; return 0; fi
    done
    return 1
}

verify_checksum() {
    local src="$1" sums name expected actual
    sums="$(dirname "$src")/SHA256SUMS"
    name="$(basename "$src")"
    if [ ! -f "$sums" ]; then
        warn "no SHA256SUMS next to the AppImage; skipping checksum verification"
        return 0
    fi
    expected="$(awk -v f="$name" '$2 == f { print $1 }' "$sums")"
    [ -n "$expected" ] || fail "SHA256SUMS has no entry for $name"
    actual="$(sha256sum "$src" | cut -d' ' -f1)"
    [ "$expected" = "$actual" ] || fail "checksum mismatch for $name (expected $expected, got $actual)"
    info "checksum verified"
}

main() {
    [ "$(uname -s)" = "Linux" ] || fail "Linux only."
    [ "$(uname -m)" = "x86_64" ] || fail "x86_64 only (this machine is $(uname -m))."
    for cmd in install sha256sum awk; do
        command -v "$cmd" >/dev/null 2>&1 || fail "required command not found: $cmd"
    done

    local src="${1:-}"
    if [ -z "$src" ]; then
        src="$(find_first "${SCRIPT_DIR}/dist/KeyboardStudio-x86_64.AppImage" \
                          "${SCRIPT_DIR}/KeyboardStudio-x86_64.AppImage")" || \
            fail "AppImage not found. Pass its path, or build it with linux/packaging/build_appimage.sh."
    fi
    [ -f "$src" ] || fail "AppImage not found at: $src"
    info "installing ${APP_NAME} from: $src"
    verify_checksum "$src"

    if ! ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
        warn "libfuse2 not detected. AppImages need it. On Ubuntu 24.04+: sudo apt install libfuse2t64"
        warn "or run the app with: ${APP_DIR}/KeyboardStudio.AppImage --appimage-extract-and-run"
    fi

    mkdir -p "$APP_DIR" "$(dirname "$BIN_LINK")" "$(dirname "$DESKTOP_FILE")" "$(dirname "$ICON_FILE")"
    install -m 0755 "$src" "${APP_DIR}/KeyboardStudio.AppImage"
    ln -sfn "${APP_DIR}/KeyboardStudio.AppImage" "$BIN_LINK"
    info "command: ${BIN_LINK}"

    local icon_src
    if icon_src="$(find_first "${SCRIPT_DIR}/linux/packaging/${APP_ID}.png" "${SCRIPT_DIR}/${APP_ID}.png")"; then
        install -m 0644 "$icon_src" "$ICON_FILE"
        info "icon installed"
    else
        warn "icon not found beside the installer; the launcher entry will use a generic icon"
    fi

    cat > "$DESKTOP_FILE" <<EOF_DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
GenericName=Keyboard Lighting & Key Mapping
Comment=RGB lighting, key remapping and macros for the MK1300 V2 keyboard
Exec=${BIN_LINK} %u
Icon=${APP_ID}
Terminal=false
Categories=Utility;HardwareSettings;Settings;
Keywords=keyboard;rgb;lighting;macro;remapping;mk1300;
StartupWMClass=keyboard_studio
EOF_DESKTOP
    info "launcher entry: ${DESKTOP_FILE}"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${PREFIX}/share/applications" >/dev/null 2>&1 || true
    fi
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -q -t "${PREFIX}/share/icons/hicolor" >/dev/null 2>&1 || true
    fi

    if [ "$SKIP_UDEV" = "1" ]; then
        warn "SKIP_UDEV=1: udev rule not installed. The keyboard will only be reachable as root."
    else
        local rule_src sudo_cmd=""
        rule_src="$(find_first "${SCRIPT_DIR}/linux/packaging/99-keyboard-studio-mk1300.rules" \
                               "${SCRIPT_DIR}/dist/99-keyboard-studio-mk1300.rules" \
                               "${SCRIPT_DIR}/99-keyboard-studio-mk1300.rules")" || \
            fail "udev rule file not found beside the installer. Re-run with SKIP_UDEV=1 to skip."
        if [ "$(id -u)" -ne 0 ]; then
            command -v sudo >/dev/null 2>&1 || fail "sudo is required to install the udev rule (or re-run with SKIP_UDEV=1)."
            sudo_cmd="sudo"
        fi
        info "installing udev rule to ${UDEV_DEST} (may prompt for sudo)"
        $sudo_cmd install -m 0644 "$rule_src" "$UDEV_DEST"
        $sudo_cmd udevadm control --reload-rules
        $sudo_cmd udevadm trigger
        info "udev rule active; unplug and replug the keyboard if it was already connected"
    fi

    case ":${PATH}:" in
        *":${PREFIX}/bin:"*) ;;
        *) warn "${PREFIX}/bin is not on PATH. Launch from the app menu or run ${BIN_LINK} directly." ;;
    esac

    info "done. Launch '${APP_NAME}' from your app menu, or run: ${CMD_NAME}"
}

main "$@"
