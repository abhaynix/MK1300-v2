# Ant Esports MK1300 V2 - Linux Packaging & Distribution Guide

This document describes the packaging architecture, build pipeline, shared library dependencies, udev permissions, and deployment procedures for the Ant Esports MK1300 V2 Linux Desktop Application.

---

## 1. Distribution Artifacts

The packaging pipeline produces standalone Linux artifacts in the `dist/` directory:

| File | Purpose | Size | SHA-256 Checksum |
| :--- | :--- | :--- | :--- |
| `dist/MK1300-V2-x86_64.AppImage` | Standalone executable AppImage bundle | ~13 MB | `463935c0eaa93534fc1568d9400ba03da8a079c042fff52599d95bb0cb68c67e` |
| `dist/SHA256SUMS` | Cryptographic checksums | 92 B | - |
| `dist/99-ant-esports-mk1300.rules` | System udev permission rules for USB HID | 1.5 KB | - |

---

## 2. Packaging Architecture

The application is packaged into an **AppImage Type 2** container with zstd squashfs compression.

### AppDir Directory Layout

```text
build/AppDir/
├── AppRun                                     # Executable entrypoint script
├── mk1300_v2                                  # Native compiled ELF 64-bit Flutter binary
├── mk1300_v2.desktop                          # FreeDesktop application launcher entry
├── mk1300_v2.png                              # 256x256 Hi-DPI application icon
├── .DirIcon                                   # AppImage icon symlink/copy
├── data/                                      # Flutter asset bundles (layout JSON, icons, fonts)
│   ├── flutter_assets/
│   │   ├── assets/data/36ae_fe12.json         # Single source of truth 61-key geometry
│   │   └── assets/images/                     # SVG & PNG graphical assets
│   └── icudtl.dat                             # Unicode internationalization data
├── lib/                                       # Bundled shared libraries
│   ├── libapp.so                              # Ahead-of-Time (AOT) compiled Dart code
│   ├── libflutter_linux_gtk.so                # Flutter Linux GTK3 engine
│   ├── libhidapi-hidraw.so.0.15.0             # Bundled HIDAPI hidraw backend
│   ├── libhidapi-hidraw.so.0 -> ...           # Versioned symlink
│   ├── libhidapi-hidraw.so -> ...             # Unversioned symlink
│   ├── libhidapi-libusb.so.0.15.0             # Bundled HIDAPI libusb backend
│   ├── libhidapi-libusb.so.0 -> ...           # Versioned symlink
│   └── libhidapi-libusb.so -> ...             # Unversioned symlink
├── etc/udev/rules.d/
│   └── 99-ant-esports-mk1300.rules            # Embedded udev rules reference
└── usr/
    ├── bin/
    ├── lib/
    ├── lib/udev/rules.d/
    └── share/
        ├── applications/mk1300_v2.desktop
        └── icons/hicolor/256x256/apps/mk1300_v2.png
```

---

## 3. Shared Library Dependency Audit

Running `ldd` on the release binary (`build/linux/x64/release/bundle/mk1300_v2`) yields:

- **System Core Libraries** (Standard across all modern Linux distributions):
  - `libc.so.6`, `libm.so.6`, `libpthread.so.0`, `libdl.so.2` (glibc 2.35+)
  - `libstdc++.so.6`, `libgcc_s.so.1` (GCC 11+)
- **Desktop UI & Windowing Libraries**:
  - `libgtk-3.so.0`, `libgdk-3.so.0` (GTK+ 3.24+)
  - `libglib-2.0.so.0`, `libgobject-2.0.so.0`, `libgio-2.0.so.0` (GLib 2.72+)
  - `libcairo.so.2`, `libpango-1.0.so.0`
- **Graphics & Display Protocols**:
  - `libepoxy.so.0`
  - `libX11.so.6`, `libxcb.so.1`
  - `libwayland-client.so.0`, `libwayland-egl.so.1`
- **Application-Specific & Bundled Libraries**:
  - `libflutter_linux_gtk.so` (Bundled in `lib/`)
  - `libhidapi-hidraw.so.0` / `libhidapi-libusb.so.0` (Bundled into AppDir `lib/` to guarantee portability across distributions where `libhidapi` is not preinstalled).

### `AppRun` Environment Initialization

The `AppRun` script configures the dynamic linker and desktop data directories prior to launching the Flutter executable:

```bash
#!/bin/bash
set -e

HERE="$(dirname "$(readlink -f "${0}")")"
export APPDIR="${HERE}"
export LD_LIBRARY_PATH="${APPDIR}/lib:${LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="${APPDIR}/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

exec "${APPDIR}/mk1300_v2" "$@"
```

---

## 4. USB Device Permissions (udev Rules)

Linux protects `/dev/hidraw*` devices by default, restricting access to `root`. To permit seamless, non-root communication with the MK1300 V2 keyboard, install the provided udev rule file:

### File: `linux/packaging/99-ant-esports-mk1300.rules`

```udev
# Ant Esports MK1300 V2 Mechanical Gaming Keyboard
# Vendor ID (VID): 0x36AE, Product ID (PID): 0xFE12

# HIDRAW subsystem rules (used by hidapi-hidraw)
KERNEL=="hidraw*", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", GROUP="plugdev", TAG+="uaccess"

# USB subsystem fallback rules (used by libusb / direct USB access)
SUBSYSTEM=="usb", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", GROUP="plugdev", TAG+="uaccess"
```

### Installation Steps

1. Copy the rule file to the system udev directory:
   ```bash
   sudo cp dist/99-ant-esports-mk1300.rules /etc/udev/rules.d/
   ```
2. Reload and trigger udev:
   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```
3. Re-plug the MK1300 V2 keyboard into the USB port. The active desktop user session will receive read/write permissions via `systemd-logind` ACLs (`uaccess`).

---

## 5. FreeDesktop Desktop Entry Specification

File: `linux/packaging/mk1300_v2.desktop`

```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Ant Esports MK1300 V2
GenericName=Gaming Keyboard Manager
Comment=Configuration software for Ant Esports MK1300 V2 Mechanical Gaming Keyboard
Exec=mk1300_v2 %u
Icon=mk1300_v2
Terminal=false
Categories=Utility;HardwareSettings;Settings;
Keywords=ant;esports;keyboard;rgb;lighting;gaming;macro;remapping;mk1300;
StartupWMClass=mk1300_v2
```

---

## 6. How to Build the AppImage from Source

Execute the build script:

```bash
./linux/packaging/build_appimage.sh
```

The script will:
1. Verify or execute `flutter build linux --release`.
2. Populate `build/AppDir/` with binaries, assets, AppRun, desktop entries, and icons.
3. Automatically bundle `libhidapi` shared libraries.
4. Use `linux/packaging/runtime-x86_64` and `appimagetool` to package `dist/MK1300-V2-x86_64.AppImage`.
5. Compute and update `dist/SHA256SUMS`.
