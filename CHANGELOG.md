# Changelog

All notable changes are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- Renamed the application to **Keyboard Studio** (publisher: ExDev). The
  Flutter package, binary, application ID (`dev.exdevx.keyboard_studio`), desktop
  entry, and udev rule file were renamed to match.
- Replaced branded icons, window title, and background with the new logo.
- Fixed `AppRun`: `XDG_DATA_DIRS` pointed to `$APPDIR/share`; the desktop data
  lives under `$APPDIR/usr/share`.
- `build_appimage.sh` no longer depends on hardcoded developer paths for
  `appimagetool`. Set `APPIMAGETOOL` or put the tool on `PATH`. The icon is
  now installed at its real 512x512 size.

### Added
- `install.sh` and `uninstall.sh` for per-user installation, with checksum
  verification, a launcher entry, and an optional system udev rule.
- Flutter CI workflow (`.github/workflows/flutter-ci.yml`): analyze, test,
  release build, and AppImage artifact.
- `LICENSE` (MIT), `NOTICE.md` (trademark and third-party notices).

### Removed
- Vendor application bundle (`extracted/`), including vendor firmware `.bin`
  files and an unpacked Electron `app.asar`. These are not redistributable.
- The previously committed AppImage and its checksum, which carried the old
  branding.
- Unused background asset `bg2.png`.
- `.github/workflows/dart.yml`. It ran `dart test` on a Flutter project.
