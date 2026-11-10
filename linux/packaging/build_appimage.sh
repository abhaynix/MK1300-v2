#!/bin/bash
# Keyboard Studio: AppImage packaging.
#
# Builds the Flutter release bundle if it is missing, assembles an AppDir,
# bundles libhidapi, and packs dist/KeyboardStudio-x86_64.AppImage.
#
# appimagetool is located via $APPIMAGETOOL, then PATH, then ./tools/appimagetool.
set -euo pipefail

APP_ID="dev.exdevx.keyboard_studio"
BINARY_NAME="keyboard_studio"
APP_NAME="KeyboardStudio"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUNDLE_DIR="${PROJECT_ROOT}/build/linux/x64/release/bundle"
APPDIR="${PROJECT_ROOT}/build/AppDir"
DIST_DIR="${PROJECT_ROOT}/dist"
APPIMAGE_OUTPUT="${DIST_DIR}/${APP_NAME}-x86_64.AppImage"
RUNTIME_FILE="${SCRIPT_DIR}/runtime-x86_64"

find_appimagetool() {
    if [ -n "${APPIMAGETOOL:-}" ] && [ -x "${APPIMAGETOOL}" ]; then
        echo "${APPIMAGETOOL}"; return 0
    fi
    if command -v appimagetool >/dev/null 2>&1; then
        command -v appimagetool; return 0
    fi
    if [ -x "${PROJECT_ROOT}/tools/appimagetool" ]; then
        echo "${PROJECT_ROOT}/tools/appimagetool"; return 0
    fi
    return 1
}

echo "=== Packaging ${APP_NAME} AppImage ==="

APPIMAGETOOL_BIN="$(find_appimagetool)" || {
    echo "ERROR: appimagetool not found. Set APPIMAGETOOL=/path/to/appimagetool or put it on PATH." >&2
    exit 1
}
echo "Using appimagetool: ${APPIMAGETOOL_BIN}"

# 1. Release bundle
if [ ! -f "${BUNDLE_DIR}/${BINARY_NAME}" ]; then
    echo "Release bundle not found; running flutter build linux --release..."
    (cd "${PROJECT_ROOT}" && flutter build linux --release)
fi

# 2. Fresh AppDir
echo "Preparing AppDir..."
rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr/bin" "${APPDIR}/usr/lib" "${APPDIR}/usr/share/applications" \
         "${APPDIR}/usr/share/icons/hicolor/512x512/apps" "${APPDIR}/lib"

# 3. Flutter bundle and entrypoint
cp -r "${BUNDLE_DIR}/"* "${APPDIR}/"
cp "${SCRIPT_DIR}/AppRun" "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# 4. Desktop entry and icon (icon must be 512x512, referenced by Icon= in the desktop file)
cp "${SCRIPT_DIR}/${APP_ID}.desktop" "${APPDIR}/${APP_ID}.desktop"
cp "${SCRIPT_DIR}/${APP_ID}.desktop" "${APPDIR}/usr/share/applications/${APP_ID}.desktop"
cp "${SCRIPT_DIR}/${APP_ID}.png" "${APPDIR}/${APP_ID}.png"
cp "${SCRIPT_DIR}/${APP_ID}.png" "${APPDIR}/.DirIcon"
cp "${SCRIPT_DIR}/${APP_ID}.png" "${APPDIR}/usr/share/icons/hicolor/512x512/apps/${APP_ID}.png"

# 5. Bundle hidapi shared libraries (the target system may not have them)
HIDRAW_SO=$(find /usr/lib/x86_64-linux-gnu -name "libhidapi-hidraw.so*" 2>/dev/null | grep -E '\.so(\.[0-9]+)*$' | head -n 1 || true)
LIBUSB_SO=$(find /usr/lib/x86_64-linux-gnu -name "libhidapi-libusb.so*" 2>/dev/null | grep -E '\.so(\.[0-9]+)*$' | head -n 1 || true)

if [ -n "${HIDRAW_SO}" ]; then
    echo "Bundling ${HIDRAW_SO}..."
    cp -d "${HIDRAW_SO}"* "${APPDIR}/lib/" 2>/dev/null || cp "${HIDRAW_SO}" "${APPDIR}/lib/"
    (cd "${APPDIR}/lib" && ln -sf libhidapi-hidraw.so.*.* libhidapi-hidraw.so.0 2>/dev/null || true)
    (cd "${APPDIR}/lib" && ln -sf libhidapi-hidraw.so.0 libhidapi-hidraw.so 2>/dev/null || true)
else
    echo "WARNING: libhidapi-hidraw not found on build host; the AppImage will need it installed." >&2
fi

if [ -n "${LIBUSB_SO}" ]; then
    echo "Bundling ${LIBUSB_SO}..."
    cp -d "${LIBUSB_SO}"* "${APPDIR}/lib/" 2>/dev/null || cp "${LIBUSB_SO}" "${APPDIR}/lib/"
    (cd "${APPDIR}/lib" && ln -sf libhidapi-libusb.so.*.* libhidapi-libusb.so.0 2>/dev/null || true)
    (cd "${APPDIR}/lib" && ln -sf libhidapi-libusb.so.0 libhidapi-libusb.so 2>/dev/null || true)
fi

# 6. udev rule ships beside the AppImage for install.sh (it is not placed inside the AppDir)
mkdir -p "${DIST_DIR}"
cp "${SCRIPT_DIR}/99-keyboard-studio-mk1300.rules" "${DIST_DIR}/99-keyboard-studio-mk1300.rules"

# 7. Pack
rm -f "${APPIMAGE_OUTPUT}"
TOOL_ARGS=("-n")
if [ -f "${RUNTIME_FILE}" ]; then
    echo "Using offline runtime: ${RUNTIME_FILE}"
    TOOL_ARGS+=("--runtime-file" "${RUNTIME_FILE}")
fi
echo "Packing ${APPIMAGE_OUTPUT}..."
ARCH=x86_64 "${APPIMAGETOOL_BIN}" --appimage-extract-and-run "${TOOL_ARGS[@]}" "${APPDIR}" "${APPIMAGE_OUTPUT}" || \
ARCH=x86_64 "${APPIMAGETOOL_BIN}" "${TOOL_ARGS[@]}" "${APPDIR}" "${APPIMAGE_OUTPUT}"
chmod +x "${APPIMAGE_OUTPUT}"

# 8. Checksums
(cd "${DIST_DIR}" && sha256sum "$(basename "${APPIMAGE_OUTPUT}")" > SHA256SUMS)
echo "Done: ${APPIMAGE_OUTPUT}"
