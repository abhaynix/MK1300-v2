<p align="center">
  <img src="assets/branding/logo-1024.png" width="160" alt="Keyboard Studio logo">
</p>

<h1 align="center">Keyboard Studio</h1>

<p align="center">
  A native Linux utility for RGB lighting, key remapping and macros on the MK1300 V2 keyboard.
</p>

> **Independent project.** Keyboard Studio is not affiliated with, endorsed by, or
> sponsored by Ant Esports. "MK1300 V2" is used only to identify compatible hardware.
> See [NOTICE.md](NOTICE.md).

---

## Features

- **Lighting:** 22 hardware lighting modes with speed, brightness (levels 0 to 4), and direction control.
- **Per-key RGB:** a 61-key visual layout with key selection and a custom color canvas.
- **Key remapping:** Layer 0 (main) and Layer 1 (Fn), with a pending-changes model. Changes apply only when you press Apply.
- **Macros:** 16 macro slots compiled to the device's 4 KB EEPROM format, with JSON import and export.
- **Offline simulator:** a mock HID device lets you develop and test without hardware.

### Not implemented yet

- Music-reactive lighting (planned: PipeWire or PulseAudio monitor capture)
- Lighting profile import and export
- A hosted one-line installer (available after the first release is published)

Hardware write status and firmware limits: see [docs/known-limitations.md](docs/known-limitations.md).

---

## Installation

### Option A: AppImage and installer script (recommended)

1. Get `KeyboardStudio-x86_64.AppImage`, `SHA256SUMS`, and `99-keyboard-studio-mk1300.rules`
   (from a release or from `dist/` after a local build).
2. Review the installer, then run it:

   ```bash
   less install.sh
   ./install.sh path/to/KeyboardStudio-x86_64.AppImage
   ```

   The installer verifies the checksum, copies the AppImage to `~/.local/share/keyboard-studio/`,
   creates a launcher entry and icon, and installs the udev rule to
   `/etc/udev/rules.d/` (requires sudo). Set `SKIP_UDEV=1` to skip the udev step.

3. Unplug and replug the keyboard.

To remove everything:

```bash
./uninstall.sh            # keeps your config
./uninstall.sh --purge    # also deletes ~/.config/keyboard-studio
```

Requirements: Linux x86_64. AppImages need FUSE 2 (`libfuse2t64` on Ubuntu 24.04+), or run with
`--appimage-extract-and-run`.

### Option B: build from source

Prerequisites: Flutter stable (3.19 or newer), `clang`, `cmake`, `ninja-build`,
`pkg-config`, `libgtk-3-dev`, `libhidapi-dev`.

```bash
flutter pub get
flutter analyze
flutter test
flutter build linux --release
./linux/packaging/build_appimage.sh     # needs appimagetool: set APPIMAGETOOL=/path/to/appimagetool
```

The release binary is at `build/linux/x64/release/bundle/keyboard_studio`.

---

## Hardware and permissions

- USB identifiers: VID `0x36AE`, PID `0xFE12`, HID interface 1, usage page `0xFF00`, usage `0x0002`, 64-byte reports.
- Without the udev rule, `/dev/hidraw*` is root-only. The rule grants access to the active desktop session (`uaccess`) and to the `plugdev` group.
- **Physical writes are gated by default.** `KeyboardService.isHardwareWriteGated` starts `true`, and writes to the device are blocked until the gate is lifted. See [docs/known-limitations.md](docs/known-limitations.md) before changing this.

### Verification status

| Area | Status |
| --- | --- |
| Protocol and layout | Derived from static analysis of the vendor software. See `docs/usb-hid-protocol.md`. |
| Hardware session log | `docs/hardware-test-results.md` records an earlier in-vivo session. **Not re-run during the rebrand pass.** |
| Unit and widget tests | Present in `test/`. Not executed in the rebrand environment (no Flutter SDK). Run `flutter test`. |
| Installer and uninstaller | Exercised in a simulated temp HOME with a stub AppImage (checksum failure, install, uninstall). Not tested on a real desktop install. |

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Device not found | Check `lsusb -d 36ae:fe12`. Confirm the udev rule is installed and replug the keyboard. |
| Permission denied on `/dev/hidraw*` | Re-run `./install.sh` (or install the rule), reload udev, and replug. |
| AppImage fails to start with a FUSE error | Install `libfuse2t64`, or run with `--appimage-extract-and-run`. |
| Writes do nothing | Hardware writes are gated. See the gate note above. |

---

## Repository layout

```
lib/                      Flutter app (features, hardware, core)
linux/                    GTK runner, CMake, AppImage packaging
assets/                   images, branding, and layout data (36ae_fe12.json)
docs/                     protocol, architecture, and test documentation
test/                     unit, widget, and mock-device tests
install.sh / uninstall.sh per-user install and removal
```

## Contributing

Open an issue or a pull request against `main`. CI runs `flutter analyze`, `flutter test`,
and the AppImage build.

## License

MIT. See [LICENSE](LICENSE) and [NOTICE.md](NOTICE.md).
