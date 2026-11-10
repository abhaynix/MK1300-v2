# USB Device Identification: MK1300 V2

## 1. Hardware Identifiers

The target hardware is the **MK1300 V2 Mechanical Gaming Keyboard**.

| Property | Value | Representation |
|---|---|---|
| **Vendor ID (VID)** | `0x36AE` | Decimal: `13998` |
| **Product ID (PID)** | `0xFE12` | Decimal: `65042` |
| **HID Usage Page** | `0xFF00` | Decimal: `65280` (Vendor-defined) |
| **HID Usage** | `0x0002` | Decimal: `2` (Vendor Custom Interface) |
| **HID Interface** | `1` | Secondary control interface (Interface 0 is standard 6KRO/NKRO keyboard) |
| **Product Name** | `MK1300 V2 Keyboard Software` / `RS0-61K-ARGB` | OEM Model |

---

## 2. Analysis of `main/assets/vid_pid_offline.js`

In the original source tree, `main/assets/vid_pid_offline.js` contains a list of OEM keyboard device profiles from the underlying keyboard solution provider (Vision / YinHua / Sinowealth).

The **active, uncommented profile** is:
```javascript
{ // XH-XJ-RS6/Q6 有华Z61-ARGB
  vendorId: 0x36ae,
  productId: 0xfe12,
  usagePage: 0xff00,
  usage: 0x0002,
}
```

### Other OEM Definitions Present (Commented Out in Firmware Codebase)
The codebase includes references to sibling hardware designs using the same Vision 9520 MCU architecture:
* `0x36AE:0xFEBB` (JinYi 9800 26-key roll-over)
* `0x36AE:0xFE9C` (XinHengWei)
* `0x36AE:0xFEAE` (TOP104-ARGB)
* `0x36AE:0xFEA3` (TK83-ARGB)
* `0x3151:0x6000` (TL68-ARGB French ISO)
* `0x36AE:0xFE81` (mini87UK-ARGB)
* `0x36AE:0xFEA4` (U98PRO YH201-ARGB)
* `0x36AE:0xFEA6` (YH203-ARGB)
* `0x36AE:0xFDA1` (ZA64-ARGB 28Pin)
* `0x36AE:0xFEAB` (V68-ARGB 28Pin)
* `0x36AE:0xFE9D` (SanPin AK08M-DS)
* `0x36AE:0xFEAD` (Z61-ARGB variant)
* `0x36AE:0xFCAB` (9-Key 68PRO)

This confirms that the MK1300 V2 uses the **`0x36AE:0xFE12`** firmware build specifically configured for the 61-key mechanical form factor.

---

## 3. Device Discovery & Matching Logic

In Flutter / Dart, device filtering must match:

1. **Wired Connection**:
   * Filter devices where `vendor_id == 0x36AE` and `product_id == 0xFE12`.
   * Open the interface with `usage_page == 0xFF00` and `usage == 0x0002` (or interface number 1).
   * Note: Do NOT open interface 0 (`usage_page: 0x0001, usage: 0x0006`), as that is the standard Windows keyboard input interface used by the OS for typing.
2. **Hot-Plug Handling**:
   * Listen for device arrival and removal events via OS notifications (RegisterDeviceNotification on Windows, udev on Linux).
   * Automatically query device config (`CMD 0x06, Sub 0x05`) upon connection.
