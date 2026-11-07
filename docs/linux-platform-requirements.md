# Ant Esports MK1300 V2 - Linux Platform Requirements

## 1. Scope & Platform Target

This document establishes the official platform constraints, runtime environments, native Linux HID requirements, and kernel device permissions for the **Ant Esports MK1300 V2 Linux Desktop Application**.

### Platform Scope
- **Target OS**: Linux (Ubuntu 22.04 LTS, 24.04 LTS primary; Debian 12+, Fedora 39+, Arch Linux secondary).
- **Architecture**: `x86_64` (AMD64). Future consideration for `aarch64` (ARM64).
- **Explicit Exclusion**: Windows desktop, macOS, iOS, Android, and Web platforms are strictly excluded from this application target. Windows-specific code, DLLs, manifests, and build steps are not part of the Linux desktop product.

---

## 2. Technology Stack

- **Application Framework**: Flutter Linux Desktop (Engine `GTK 3.0` embedding).
- **Programming Language**: Dart 3.x (sound null safety).
- **Native USB HID Integration**: Direct C-FFI binding to dynamic `libhidapi-hidraw.so` or `libhidapi-libusb.so`.
- **Packaging Targets**:
  1. Standalone Native Linux Bundle (`flutter build linux --release`).
  2. Debian Package (`.deb`) with automated udev rule installation.
  3. Standalone AppImage for universal distribution across Linux distributions.

---

## 3. Native Linux HID Subsystem (`hidapi`)

Linux provides two distinct HID backends via `hidapi`:
1. `hidapi-hidraw` (`libhidapi-hidraw.so.0`): Uses Linux kernel `/dev/hidraw*` character devices. **(Recommended primary backend)**.
2. `hidapi-libusb` (`libhidapi-libusb.so.0`): Uses userspace `libusb-1.0` to detach kernel drivers and claim USB interfaces directly.

### Dynamic Library Resolution Strategy
The Flutter Dart FFI layer (`hidapi_binding.dart`) resolves the shared library in the following priority order:
1. Application bundle directory: `./lib/libhidapi-hidraw.so`
2. System `hidraw` library: `libhidapi-hidraw.so.0`, `libhidapi-hidraw.so`
3. System fallback: `libhidapi-libusb.so.0`, `libhidapi-libusb.so`
4. Generic fallback: `libhidapi.so.0`, `libhidapi.so`

If no native `hidapi` dynamic library is present or if USB devices cannot be opened due to sandbox or absence of hardware, the application cleanly falls back to the internal `MockHidDevice` hardware simulator without crashing.

---

## 4. Linux Kernel Device Permissions & udev Rules

### Problem Statement
By default, the Linux kernel assigns `/dev/hidraw*` devices root-only read/write permissions (`0600` or `root:root`). Standard non-root desktop users cannot send USB feature/interrupt reports without custom udev rules.

Running desktop applications with `sudo` is an anti-pattern that violates desktop security and impairs desktop environments (Wayland/X11 socket access).

### Mandatory udev Rule
A dedicated udev rule file `/etc/udev/rules.d/99-antesports-mk1300.rules` must be installed:

```udev
# Ant Esports MK1300 V2 Mechanical Gaming Keyboard (Vision 9520 MCU)
# Allow read/write access to vendor control interface for desktop users in the 'plugdev' or 'uaccess' seat

# hidraw subsystem rule with uaccess tag (systemd-logind active session)
KERNEL=="hidraw*", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", TAG+="uaccess"

# Fallback group permission for plugdev
KERNEL=="hidraw*", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", GROUP="plugdev"

# USB device rule for libusb backend
SUBSYSTEM=="usb", ATTRS{idVendor}=="36ae", ATTRS{idProduct}=="fe12", MODE="0660", TAG+="uaccess", GROUP="plugdev"
```

### udev Reload Instructions
After writing the rule file:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```
When the user replugs the keyboard, `/dev/hidraw*` will have read and write permissions granted to the active desktop session.

### Non-Root Permission-Denied Behavior
If the application detects `EACCES` (Permission Denied) when opening the device:
1. It does not crash.
2. It displays a non-intrusive warning card in the UI shell:
   *"Keyboard detected on USB, but access was denied by Linux permissions. Click here to install udev rules or view setup guide."*
3. Offers a one-click script generation to `/tmp/install-mk1300-udev.sh` that the user can review and apply with standard pkexec/sudo.

---

## 5. Linux Build & Development Dependencies

To build the native Linux application from source on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libhidapi-dev \
  libhidapi-hidraw0
```

Runtime dependencies on target user machines:
- `libgtk-3-0` (Standard on GNOME, XFCE, Cinnamon, MATE, etc.)
- `libhidapi-hidraw0` (Installed automatically as dependency by `.deb` or bundled in AppImage).
