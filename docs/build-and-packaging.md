# MK1300 V2 - Build and Deployment Guide

This guide details how to build and package the native Flutter desktop application for **Linux x86_64**.

---

## 1. System Requirements

### Linux Build Environment
- **OS**: Ubuntu 22.04 LTS, Ubuntu 24.04 LTS, Ubuntu 26.04 LTS, Debian 12+, Fedora 39+, Arch Linux.
- **Flutter SDK**: Stable channel (>= 3.19.0).
- **Core Build Tools**:
  ```bash
  sudo apt install clang cmake ninja-build g++ pkg-config libgtk-3-dev libhidapi-dev
  ```

---

## 2. Linux Release Build

1. Resolve dependencies:
   ```bash
   flutter pub get
   ```

2. Run test verification suite:
   ```bash
   flutter test
   ```

3. Build the native Linux release executable:
   ```bash
   flutter build linux --release
   ```

4. The compiled production bundle is located at:
   ```
   build/linux/x64/release/bundle/
   ```
   Containing `keyboard_studio`, `libapp.so`, `libflutter_linux_gtk.so`, and `data/`.

---

## 3. Standalone AppImage Packaging

To build the standalone, distributable `KeyboardStudio-x86_64.AppImage`:

```bash
./linux/packaging/build_appimage.sh
```

This generates:
- `dist/KeyboardStudio-x86_64.AppImage`
- `dist/SHA256SUMS`
- `dist/99-keyboard-studio-mk1300.rules`

### Running the AppImage
```bash
chmod +x dist/KeyboardStudio-x86_64.AppImage
./dist/KeyboardStudio-x86_64.AppImage
```

---

## 4. Hardware Safety Gate

By default, physical hardware writes are blocked by the safety gate in `KeyboardService`:
- `isHardwareWriteGated = true`
- If physical writes are attempted without physical verification or explicit user override, the service blocks transmission and logs a safety warning.
- The built-in mock device provider (`MockHidDevice`) enables 100% offline testing of all protocol commands, lighting sequences, key remapping, and macro EEPROM operations without risk of damaging hardware.
