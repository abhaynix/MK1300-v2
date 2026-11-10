# Notices

## Trademarks and affiliation

Keyboard Studio is an independent, community project. It is **not affiliated
with, endorsed by, or sponsored by Ant Esports** or any other manufacturer of
the MK1300 V2 keyboard. "MK1300 V2" and the USB identifiers (VID `0x36AE`,
PID `0xFE12`) are used only to describe which hardware the software is
compatible with. All other product names are the property of their owners.

Keyboard Studio contains no vendor logos, vendor application code, or vendor
firmware. Protocol details were obtained through interoperability analysis and
are documented in `docs/`.

## Third-party software

Keyboard Studio is built with the following components. Each retains its own
license, which applies to that component:

- Flutter and Dart SDK (BSD-3-Clause)
- hidapi, linked at runtime for USB HID access (dual-licensed upstream; see the
  hidapi project for terms)
- Dart packages listed in `pubspec.yaml`, including `flutter_svg`,
  `file_picker`, `ffi`, `path`, and `cupertino_icons` (see each package on
  pub.dev for its license)

Before redistributing an AppImage, include the license texts of the bundled
components with the release.
