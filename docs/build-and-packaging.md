# Ant Esports MK1300 V2 - Build and Deployment Guide

This guide details how to build and package the native Flutter desktop application for **Windows x64** and **Linux**.

---

## 1. System Requirements

### Windows Build Environment (Target Platform)
- Windows 10/11 x64.
- Visual Studio 2022 (with "Desktop development with C++" workload installed).
- Flutter SDK (stable channel, >= 3.19.0).
- Git for Windows.

### Linux Environment
- Ubuntu 22.04+ or modern Linux distribution.
- Flutter SDK (stable channel, >= 3.19.0).
- Standard build dependencies:
  ```bash
  sudo apt install clang cmake ninja-build g++ pkg-config libgtk-3-dev
  ```

---

## 2. Windows Release Build

1. Clone or open the workspace:
   ```cmd
   cd MK1300-V2
   ```

2. Fetch Flutter packages:
   ```cmd
   flutter pub get
   ```

3. Run verification test suite:
   ```cmd
   flutter test
   ```

4. Build the standalone Windows release executable:
   ```cmd
   flutter build windows --release
   ```

5. The production release is located at:
   ```
   build\windows\x64\runner\Release\
   ```

### Bundling `hidapi.dll`
When distributing the application, ensure `hidapi.dll` (x64) is co-located with `mk1300_v2.exe` in the application directory:
- The `NativeHidDevice` FFI binding will automatically search the application directory for `hidapi.dll`.
- If physical hardware is not attached, the application automatically falls back to the built-in offline hardware simulator.

---

## 3. Automated CI/CD (GitHub Actions)

A GitHub Actions workflow is provided in [`.github/workflows/build_windows.yml`](file:///home/devx/Development/MK1300-V2/.github/workflows/build_windows.yml).
- Automatically triggers on push and pull requests to `main`.
- Runs full `flutter test` validation.
- Builds the Windows release and produces downloadable artifacts: `Ant-Esports-MK1300-V2-Windows-x64.zip`.
