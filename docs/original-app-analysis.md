# Original Application Analysis: Ant Esports MK1300 V2

## 1. Executive Summary

The original application is **MK1300 V2 Keyboard Software** (Version 1.0.0, © 2026 Ant Esports), distributed as a single Windows executable installer `MK1300-V21-0-0.exe` (89,058,823 bytes).

Static reverse engineering using **REA (Reverse Engineer Anything)** and binary decompilation reveals that the software is an **Electron x64 Windows desktop application** with an internal **Next.js (React 18 / Chakra UI / Tailwind CSS)** single-page application communicating directly with the hardware via Chromium's **WebHID API** (`navigator.hid`).

---

## 2. Binary & Package Anatomy

### 2.1 Outer Installer Container
* **Format**: PE32 executable for MS Windows (GUI), Intel i386, Nullsoft Installer (NSIS self-extracting archive).
* **Sections**: 5 sections (`.text`, `.rdata`, `.data`, `.ndata`, `.rsrc`).
* **Payload**: Extracts an internal 7-Zip compressed archive `app-64.7z` containing the Electron application bundle.

### 2.2 Unpacked Electron Bundle Structure
```
MK1300-V2/
├── MK1300-V21-0-0.exe          # Original NSIS installer
└── extracted/
    ├── app-64.7z               # 7-Zip archive containing full Electron runtime
    └── app.asar                # Core application archive (17,198,891 bytes)
        ├── package.json        # Electron package metadata
        ├── main/
        │   ├── index.js        # Electron main process entry point (148 lines)
        │   ├── preload.js      # Context bridge / Preload script (empty)
        │   ├── assets/
        │   │   ├── icon.ico    # Application icon
        │   │   ├── favicon.ico # Window icon
        │   │   └── vid_pid_offline.js # Hardware VID/PID & filter table
        │   └── utils/
        │       └── comm.js     # Permission check helper
        ├── build/              # Static Next.js export
        │   ├── index.html      # SPA HTML entry point
        │   ├── _next/static/   # Webpack bundled JavaScript chunks and CSS
        │   ├── images/         # SVG icons (keyboard, light, macro, config, etc.)
        │   └── device/         # Keyboard layout and preview assets
        └── node_modules/       # Bundled dependencies (cross-env, electron-squirrel-startup)
```

---

## 3. Technology Stack Breakdown

| Layer | Original Technology | Reconstructed Role |
|---|---|---|
| **OS Host** | Windows 10/11 x64 | Target platform |
| **Shell / Wrapper** | Electron 28+ | Window container & WebHID permissions |
| **Frontend Framework**| Next.js (Static Export) + React 18 | UI view layer, routing, and user state |
| **UI Component Library**| Chakra UI + Tailwind CSS | Buttons, modals, tabs, forms, sliders |
| **Icons / Assets** | SVG + PNG + Canvas | Keyboard visualizer & menu icons |
| **Hardware Bridge** | Chromium WebHID (`navigator.hid`) | USB HID report packet transmission |
| **Hardware Target** | Vision/YinHua 9520 MCU / Ant Esports MK1300 V2 | 61-Key ARGB Mechanical Gaming Keyboard |

---

## 4. Main Process Analysis (`main/index.js`)

The Electron main process does not use standard Node.js native bindings (like `node-hid`) or custom Electron IPC channels for hardware packets. Instead, it grants unrestricted WebHID access to the renderer:

1. **`app.commandLine.appendSwitch('disable-hid-blocklist')`**:
   Bypasses Chromium's security blocklist that prevents web apps from accessing system keyboard/mouse HID devices.
2. **`mainWindow.webContents.session.on('select-hid-device', ...)`**:
   Automatically intercepts WebHID device selection requests from `navigator.hid.requestDevice()` and selects the device if its `vendorId` and `productId` match `getPermission(vid, pid)`.
3. **`setPermissionCheckHandler` & `setDevicePermissionHandler`**:
   Authorizes `hid` permission without displaying browser prompt dialogs.
4. **Window Configuration**:
   - `width: 1800, height: 1000`
   - `minWidth: 1800, minHeight: 1000`
   - `autoHideMenuBar: true`
   - `zoomFactor: 1.0` (Fixed, zoom disabled)
   - Loads `build/index.html` in production.

---

## 5. Architectural Findings

The architecture of the original application can be summarized as:
```
┌────────────────────────────────────────────────────────┐
│                   Renderer (Next.js)                   │
│                                                        │
│  ┌───────────────────────┐  ┌───────────────────────┐  │
│  │   UI View & Tabs      │  │   Macro & Profile     │  │
│  │ (Key, Light, Config)  │  │   State Machine       │  │
│  └───────────┬───────────┘  └───────────┬───────────┘  │
│              │                          │              │
│  ┌───────────▼──────────────────────────▼───────────┐  │
│  │           Keyboard Controller Class (j)          │  │
│  │    (Layout, Lighting, Macros, Key Remapping)     │  │
│  └───────────────────────┬──────────────────────────┘  │
│                          │                             │
│  ┌───────────────────────▼──────────────────────────┐  │
│  │           Protocol Transport Layer (L, w)        │  │
│  │      Command Queue, 64-byte Packet Serializer    │  │
│  └───────────────────────┬──────────────────────────┘  │
│                          │                             │
│  ┌───────────────────────▼──────────────────────────┐  │
│  │     Chromium WebHID API (navigator.hid)          │  │
│  └───────────────────────┬──────────────────────────┘  │
└──────────────────────────┼─────────────────────────────┘
                           │ USB HID 64-byte Reports
┌──────────────────────────▼─────────────────────────────┐
│    Ant Esports MK1300 V2 (VID: 0x36AE, PID: 0xFE12)    │
│              Vision 9520 MCU Hardware                  │
└────────────────────────────────────────────────────────┘
```
