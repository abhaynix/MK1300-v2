# IPC Communication Reference: Original vs Native Flutter

## 1. Original Electron IPC Architecture

An audit of `main/index.js` and `main/preload.js` revealed:
* `main/preload.js` is empty (2 lines of comments only).
* `main/index.js` does NOT declare any `ipcMain.on` or `ipcMain.handle` listeners.
* The original architecture completely bypassed Electron IPC for hardware communication by utilizing Chromium's **WebHID API** (`navigator.hid`) with `--disable-hid-blocklist`.
* All device discovery, reading, writing, and queueing was executed directly within the renderer browser environment.

| Channel / Mechanism | Direction | Arguments | Return | Hardware Communication | Evidence |
|---|---|---|---|---|---|
| `navigator.hid.getDevices()` | In-Renderer | None | List of connected HID devices | Queries Chromium HID layer | `build/_next/static/chunks/app/page-*.js` |
| `navigator.hid.requestDevice()` | In-Renderer | Filter `[{vendorId: 13998, productId: 65042, usagePage: 65280, usage: 2}]` | Selected HID device | Intercepted by `select-hid-device` in `main/index.js` | `main/index.js` L49-73 |
| `device.sendReport(0, data)` | In-Renderer | Report ID 0, 64-byte `Uint8Array` | Promise<void> | Writes 64-byte USB Interrupt packet | `build/_next/static/chunks/app/page-*.js` L7623 |
| `device.oninputreport` / `addEventListener('inputreport')` | In-Renderer | Event listener | Inbound 64-byte report buffer | Reads keyboard responses and live hardware events | `build/_next/static/chunks/app/page-*.js` |
| `globalShortcut.register` | OS to Main | `'CommandOrControl+\'` | None | No (Toggles DevTools in dev mode) | `main/index.js` L99-102 |
| `setWindowOpenHandler` | Renderer to OS | URL | Open in default browser | No | `main/index.js` L140-145 |

---

## 2. Reconstructed Flutter Architecture (Clean Separation)

Because Flutter is a native application framework without a web browser sandbox, we do not need WebHID or Chromium flags. Instead, we implement a **Clean Service Layer** using native USB HID bindings:

```
┌────────────────────────────────────────────────────────┐
│                   Flutter UI Layer                     │
│         (KeyRemapPage, LightingPage, MacroPage)        │
└──────────────────────────┬─────────────────────────────┘
                           │ Provider / Riverpod / Notifier
┌──────────────────────────▼─────────────────────────────┐
│             Keyboard Controller Service                │
│    (High-level business logic, Profile, HSV, Macros)   │
└──────────────────────────┬─────────────────────────────┘
                           │ Data models & Packets
┌──────────────────────────▼─────────────────────────────┐
│           HID Hardware Abstraction Layer (HAL)         │
│          (hidapi / Windows Win32 Raw HID / FFI)        │
└──────────────────────────┬─────────────────────────────┘
                           │ 64-byte Interrupt Reports
┌──────────────────────────▼─────────────────────────────┐
│             MK1300 V2 Hardware             │
└────────────────────────────────────────────────────────┘
```
