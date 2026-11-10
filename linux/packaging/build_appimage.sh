#!/bin/bash
set -e

# ==============================================================================
# Ant Esports MK1300 V2 - AppImage Build & Packaging Script
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUNDLE_DIR="${PROJECT_ROOT}/build/linux/x64/release/bundle"
APPDIR="${PROJECT_ROOT}/build/AppDir"
DIST_DIR="${PROJECT_ROOT}/dist"
APPIMAGE_OUTPUT="${DIST_DIR}/MK1300-V2-x86_64.AppImage"
RUNTIME_FILE="${PROJECT_ROOT}/linux/packaging/runtime-x86_64"

echo "=== Building Ant Esports MK1300 V2 AppImage ==="
echo "Project Root: ${PROJECT_ROOT}"
echo "Bundle Dir:   ${BUNDLE_DIR}"
echo "AppDir:       ${APPDIR}"
echo "Dist Dir:     ${DIST_DIR}"

# 1. Verify or trigger release build
if [ ! -f "${BUNDLE_DIR}/mk1300_v2" ]; then
    echo "Release bundle not found. Building with flutter build linux --release..."
    cd "${PROJECT_ROOT}"
    flutter build linux --release
fi

# 2. Prepare clean AppDir structure
echo "Preparing AppDir structure..."
rm -rf "${APPDIR}"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/lib"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"
mkdir -p "${APPDIR}/usr/lib/udev/rules.d"
mkdir -p "${APPDIR}/etc/udev/rules.d"
mkdir -p "${APPDIR}/lib"

# 3. Copy Flutter release bundle
echo "Copying Flutter bundle files..."
cp -r "${BUNDLE_DIR}/"* "${APPDIR}/"

# 4. Install AppRun entrypoint
echo "Installing AppRun entrypoint..."
cp "${PROJECT_ROOT}/linux/packaging/AppRun" "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# 5. Install Desktop File
echo "Installing Desktop entry..."
cp "${PROJECT_ROOT}/linux/packaging/mk1300_v2.desktop" "${APPDIR}/mk1300_v2.desktop"
cp "${PROJECT_ROOT}/linux/packaging/mk1300_v2.desktop" "${APPDIR}/usr/share/applications/mk1300_v2.desktop"

# 6. Install Icons
echo "Installing application icons..."
cp "${PROJECT_ROOT}/linux/packaging/mk1300_v2.png" "${APPDIR}/mk1300_v2.png"
cp "${PROJECT_ROOT}/linux/packaging/mk1300_v2.png" "${APPDIR}/.DirIcon"
cp "${PROJECT_ROOT}/linux/packaging/mk1300_v2.png" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/mk1300_v2.png"

# 7. Install udev rules
echo "Installing udev rules..."
cp "${PROJECT_ROOT}/linux/packaging/99-ant-esports-mk1300.rules" "${APPDIR}/usr/lib/udev/rules.d/"
cp "${PROJECT_ROOT}/linux/packaging/99-ant-esports-mk1300.rules" "${APPDIR}/etc/udev/rules.d/"

# 8. Bundle non-standard shared libraries (libhidapi)
echo "Auditing and bundling shared libraries..."
HIDRAW_SO=$(find /usr/lib/x86_64-linux-gnu -name "libhidapi-hidraw.so*" 2>/dev/null | grep -E '\.so(\.[0-9]+)*$' | head -n 1 || true)
LIBUSB_SO=$(find /usr/lib/x86_64-linux-gnu -name "libhidapi-libusb.so*" 2>/dev/null | grep -E '\.so(\.[0-9]+)*$' | head -n 1 || true)

if [ -n "${HIDRAW_SO}" ]; then
    echo "Bundling ${HIDRAW_SO}..."
    cp -d "${HIDRAW_SO}"* "${APPDIR}/lib/" 2>/dev/null || cp "${HIDRAW_SO}" "${APPDIR}/lib/"
    (cd "${APPDIR}/lib" && ln -sf libhidapi-hidraw.so.*.* libhidapi-hidraw.so.0 2>/dev/null || true)
    (cd "${APPDIR}/lib" && ln -sf libhidapi-hidraw.so.0 libhidapi-hidraw.so 2>/dev/null || true)
fi

if [ -n "${LIBUSB_SO}" ]; then
    echo "Bundling ${LIBUSB_SO}..."
    cp -d "${LIBUSB_SO}"* "${APPDIR}/lib/" 2>/dev/null || cp "${LIBUSB_SO}" "${APPDIR}/lib/"
    (cd "${APPDIR}/lib" && ln -sf libhidapi-libusb.so.*.* libhidapi-libusb.so.0 2>/dev/null || true)
    (cd "${APPDIR}/lib" && ln -sf libhidapi-libusb.so.0 libhidapi-libusb.so 2>/dev/null || true)
fi

# 9. Locate appimagetool
APPIMAGETOOL_BIN=$(which appimagetool 2>/dev/null || true)
if [ -z "${APPIMAGETOOL_BIN}" ]; then
    if [ -x "/home/devx/.local/bin/appimagetool" ]; then
        APPIMAGETOOL_BIN="/home/devx/.local/bin/appimagetool"
    elif [ -x "/tmp/tools/appimagetool" ]; then
        APPIMAGETOOL_BIN="/tmp/tools/appimagetool"
    fi
fi

if [ -z "${APPIMAGETOOL_BIN}" ]; then
    echo "ERROR: appimagetool executable not found in PATH, ~/.local/bin, or /tmp/tools."
    exit 1
fi

echo "Using appimagetool: ${APPIMAGETOOL_BIN}"

# 10. Package into AppImage
mkdir -p "${DIST_DIR}"
rm -f "${APPIMAGE_OUTPUT}"

TOOL_ARGS=("-n")
if [ -f "${RUNTIME_FILE}" ]; then
    echo "Using offline runtime file: ${RUNTIME_FILE}"
    TOOL_ARGS+=("--runtime-file" "${RUNTIME_FILE}")
fi

echo "Packaging AppImage into ${APPIMAGE_OUTPUT}..."
ARCH=x86_64 "${APPIMAGETOOL_BIN}" --appimage-extract-and-run "${TOOL_ARGS[@]}" "${APPDIR}" "${APPIMAGE_OUTPUT}" || \
ARCH=x86_64 "${APPIMAGETOOL_BIN}" "${TOOL_ARGS[@]}" "${APPDIR}" "${APPIMAGE_OUTPUT}"

chmod +x "${APPIMAGE_OUTPUT}"

# 11. Generate SHA256 checksums
echo "Generating SHA256SUMS..."
(cd "${DIST_DIR}" && sha256sum "$(basename "${APPIMAGE_OUTPUT}")" > SHA256SUMS)

# Copy udev rules to dist/ for user convenience
cp "${PROJECT_ROOT}/linux/packaging/99-ant-esports-mk1300.rules" "${DIST_DIR}/99-ant-esports-mk1300.rules"

echo "=== AppImage Package Complete ==="
ls -lh "${DIST_DIR}"
cat "${DIST_DIR}/SHA256SUMS"
