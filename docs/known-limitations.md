# Known Limitations & Hardware Boundaries

## 1. Verified vs Unverified Findings

| Domain | Item | Static Evidence Status | Hardware Verification Status | Notes / Limitations |
|---|---|---|---|---|
| **USB Identity** | VID `0x36AE`, PID `0xFE12` | 100% Verified in `vid_pid_offline.js` & `page-*.js` | Static | Active device profile confirmed |
| | Usage Page `0xFF00`, Usage `0x0002` | 100% Verified in WebHID filters | Static | Vendor interface 1 |
| **Protocol** | Command `0x06` Subcommands (0x05, 0x0A, 0x0B, 0x08, 0x09, 0x0C, 0x0D, 0x10, 0x12, 0x13, 0x14, 0xFB, 0xFC, 0x0F) | 100% Verified from decompiled JavaScript classes | Static | Byte offsets, little-endian ordering, and packet sizes completely mapped |
| | Firmware IAP / Bootloader (`0x55`, `0x5A`) | Code decompiled | ⚠️ **Unverified / Unsafe** | Flashing bootloader firmware poses bricking risk without official signed bin files. Omitted from standard UI. |
| **Lighting** | 22 Lighting modes | 100% Verified from `36ae_fe12.json` | Static | All mode IDs (0 to 21) and speed/brightness flags confirmed |
| | Per-key Custom RGB | 100% Verified from packet `0x12` & `0x14` | Static | 3 bytes per key [R, G, B] |
| **Key Remap** | 61-Key Layout & Coordinates | 100% Verified from layout JSON | Static | Matrix rows: 5, cols: 15, key indices: 0 to 73 |
| | Main Layer & Fn Layer | 100% Verified | Static | Layer parameter `0` or `1` in packets |
| **Macros** | 4096-byte EEPROM layout | 100% Verified from encoding functions `D` and `A` | Static | Pointer table at offset 0..63; 4-byte action records with flags |
| **OS Support** | Windows x64 | Primary target | Full support | Using `hidapi.dll` / Win32 HID APIs |
| | Linux x64 | Supported | Full support | Using `libhidapi-hidraw.so` (requires udev rule for non-root USB access) |

---

## 2. Inferred / Unknown Behavior

1. **Physical Battery Thresholds**:
   The battery reading is reported as a raw byte in `resp[13]`. In wired mode, the keyboard reports 100 or charging status, but battery drain curves on wireless siblings were not directly observable without live hardware telemetry.
2. **Key Debounce Settings**:
   The original UI exposes general performance settings and auto-sleep timers, but does not expose variable millisecond switch debounce rates in the 61-key build.
3. **Hardware Write Frequency Guard**:
   Writing to the 4096-byte macro EEPROM too frequently could wear flash memory. Flutter implementation should debounce bulk saves and enforce user confirmation.
