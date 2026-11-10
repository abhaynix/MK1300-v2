# Ant Esports MK1300 V2 - Feature Parity Matrix

This matrix compares the original vendor application against the Flutter Linux desktop implementation.

| Feature | Original application | Flutter implementation | Test status | Hardware status |
|---|---|---|---|---|
| **USB Discovery & Identification** | WebHID enumeration with VID `0x36AE`, PID `0xFE12` | Linux HIDAPI via Dart FFI (`LinuxHidDevice`), non-blocking poll | Tested (`mock_hid_device_test.dart`) | **Pending Physical Verification** |
| **Simulated Device Mode** | Built-in `"demo"` mode | Full `MockHidDevice` with memory state & failure simulation | Tested (`mock_hid_device_test.dart`) | Simulated (Verified) |
| **Dashboard Interface** | Electron main window, connection pill, device card | Flutter `DashboardPage` with real-time status and diagnostics | Tested (`dashboard_and_visualizer_test.dart`) | Simulated (Verified) |
| **61-Key Keyboard Visualizer** | Canvas / DOM elements based on layout JSON | Custom Flutter `KeyboardVisualizer` using ANSI 61 geometry | Tested (`dashboard_and_visualizer_test.dart`) | Simulated (Verified) |
| **Lighting Mode Selection** | 22 hardware animation presets | `LightingPage` selector with all 22 modes and parameter constraints | Tested (`lighting_studio_test.dart`) | **Pending Physical Verification** |
| **Lighting Parameters** | Brightness (0-4), Speed (0-4), Direction (1-2) | Reactive sliders and segmented direction controls | Tested (`lighting_studio_test.dart`) | **Pending Physical Verification** |
| **Color Control & Palette** | Dynamic rainbow or single custom color via HSV | Full HSV wheel / slider picker, 8-swatch memory palette | Tested (`hsv_color_test.dart`, `lighting_studio_test.dart`) | **Pending Physical Verification** |
| **Local Lighting Preview** | CSS / WebGL approximate animations | `LightingPreviewEngine` with 30/60 FPS ticker and lifecycle pause | Tested (`lighting_studio_test.dart`) | Simulated (Verified) |
| **Lighting Hardware Sync** | `CMD 0x06, 0x0A` (read), `0x06, 0x0B` (write) | `KeyboardService.applyLightingState()` with readback confirmation | Tested (`lighting_synchronization_test.dart`) | **Pending Physical Verification** |
| **Unsolicited Hardware Events** | Inbound `0xAA, 0xFA` broadcast event listener | `UnsolicitedEventDecoder` parsing background hardware events | Tested (`lighting_synchronization_test.dart`) | **Pending Physical Verification** |
| **Key Remapping: Main Layer** | Layer 0 configuration with 4-byte key descriptors | `KeyRemappingPage` Layer 0 interactive remapping | Tested (`key_remapping_test.dart`) | **Pending Physical Verification** |
| **Key Remapping: Fn Layer** | Layer 1 secondary configuration | `KeyRemappingPage` Layer 1 switching and secondary assignments | Tested (`key_remapping_test.dart`) | **Pending Physical Verification** |
| **Key Assignment Catalog** | Categories: Basic, Media, Mouse, Shortcut, System | `KeyCatalog` with 6 searchable categories and fast filter | Tested (`key_remapping_test.dart`) | Simulated (Verified) |
| **Key Remap Pending State** | Immediate write or local store | Explicit Transactional Pattern: Pending badge, Amber dot, Apply/Revert | Tested (`key_remapping_test.dart`) | Simulated (Verified) |
| **Single Key Write** | `CMD 0x06, 0x10` (7-byte payload, LE offset) | `PacketBuilder.buildWriteSingleKeyPacket` | Tested (`key_remapping_test.dart`) | **Pending Physical Verification** |
| **Batch Keymap Sync** | `CMD 0x06, 0x08` (read), `0x06, 0x09` (write chunks) | `PacketBuilder` chunk serializers & readback routines | Tested (`key_remapping_test.dart`) | **Pending Physical Verification** |
| **Per-Key Custom RGB** | `CMD 0x06, 0x13` (read), `0x06, 0x12` / `0x14` (write) | Integrated in visualizer, models, and PacketBuilder | Tested (`mock_hid_device_test.dart`, `packet_serialization_test.dart`) | **Pending Physical Verification** |
| **Macro Studio: 16 Slots** | 16 macro slots in 4KB EEPROM | `MacroPage` with slot list, action inspector, and editor | Tested (`macro_studio_test.dart`) | **Pending Physical Verification** |
| **Macro Compiler & Decompiler** | Functions `D(n)` and `A(e, a)` in chunk 1931 | `MacroCompiler.compileToEeprom` & `decompileFromEeprom` | Tested (`macro_studio_test.dart`) | Simulated (Verified) |
| **Macro Actions & Delays** | Key press/release, mouse buttons, delays (0-10000ms) | Full `MacroAction` model with timing, loop modes, and type flags | Tested (`macro_studio_test.dart`) | Simulated (Verified) |
| **Macro Hardware Read/Write** | `CMD 0x06, 0x0C` (read 56B), `0x06, 0x0D` (write 59B) | `KeyboardService.saveMacrosToKeyboard` & readback | Tested (`macro_studio_test.dart`) | **Pending Physical Verification** |
| **Macro Memory Reset** | `CMD 0x06, 0x0F, 0x04` | `KeyboardService.clearAllMacros` | Tested (`macro_studio_test.dart`) | **Pending Physical Verification** |
| **Profile Management** | 3 hardware profiles switched via `CMD 0x06, 0xFB` | `KeyboardService.switchProfile()` and AppShell switcher | Tested (`mock_hid_device_test.dart`) | **Pending Physical Verification** |
| **Sleep Timer Settings** | `CMD 0x06, 0xFC` (0, 120s, 300s, 600s, 1800s) | `SettingsPage` power card with dropdown options | Tested (`mock_hid_device_test.dart`) | **Pending Physical Verification** |
| **Hardware Safety Gate** | None (always wrote directly) | `isHardwareWriteGated = true` blocking unverified physical writes | Tested (`key_remapping_test.dart`, `macro_studio_test.dart`, `lighting_synchronization_test.dart`) | Gated by Policy (Verified) |
| **Linux Packaging (AppImage)** | Windows NSIS installer only | Standalone x86_64 AppImage with embedded runtime & icons (`dist/MK1300-V2-x86_64.AppImage`) | Verified (Extracted & Executed) | Linux Desktop Ready |
