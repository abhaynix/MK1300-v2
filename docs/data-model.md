# Data Model & State Structures: Ant Esports MK1300 V2

## 1. Hardware Configuration Model (`KeyboardConfig`)

Represents the physical device metadata returned by `CMD 0x06, Sub 0x05`:

```dart
class KeyboardConfig {
  final int version;          // Hardware/Board version (e.g. 0x0100)
  final int pid;              // Product ID (0xFE12)
  final int firmwareVersion;  // Firmware build number (e.g. 102)
  final int workMode;         // Current operational mode (Wired/Wireless)
  final int linkStatus;       // 0 = Off, 1 = Wired, 2 = 2.4G, 3 = BT
  final int battery;          // Battery percentage (0 - 100)
  final int charging;         // 0 = No, 1 = Charging, 2 = Full
  final int profileCount;     // Supported profiles count (3)
  final int currentProfile;   // Active profile index (0, 1, 2)
  final int layerCount;       // Supported layers count (2)
  final int currentLayer;     // Active layer (0 = Main, 1 = Fn)
  final int autoSleepTime;    // Auto-sleep timeout in seconds (e.g. 120, 300, 600)
  final String serialNumber;  // Device serial string (ASCII)

  const KeyboardConfig({
    required this.version,
    required this.pid,
    required this.firmwareVersion,
    required this.workMode,
    required this.linkStatus,
    required this.battery,
    required this.charging,
    required this.profileCount,
    required this.currentProfile,
    required this.layerCount,
    required this.currentLayer,
    required this.autoSleepTime,
    required this.serialNumber,
  });
}
```

---

## 2. Key Descriptor Model (`KeyMapping`)

Represents the physical and logical configuration of a single key on the keyboard:

```dart
class KeyMapping {
  final int keyIndex;       // Physical matrix index (0 to 126; 0 to 73 on 61-key layout)
  final String keyName;     // Default keycap legend (e.g. "Esc", "W", "Space")
  final int defaultCode;    // Default HID usage code
  final int defaultType;    // Default type (usually 32 for standard key)
  
  // Custom assigned state
  int newType;              // Remapped Category Type (32=Key, 48=Media, 16=Mouse, 96=Macro, etc.)
  int newCode1;             // Modifiers / Sub-category
  int newCode2;             // Remapped HID keycode or action ID
  int newCode3;             // Macro loop mode / wheel delta
  String newName;           // Display label for remapped action
  String colorHex;          // Custom RGB color (#RRGGBB)

  KeyMapping({
    required this.keyIndex,
    required this.keyName,
    required this.defaultCode,
    required this.defaultType,
    required this.newType,
    required this.newCode1,
    required this.newCode2,
    required this.newCode3,
    required this.newName,
    required this.colorHex,
  });
}
```

---

## 3. Lighting Configuration Model (`LightingConfig`)

Represents the complete RGB lighting system state:

```dart
enum LightingMode {
  off(0),
  staticOn(1),
  breathing(2),
  neon(3),
  spectrumCycle(4),
  horizontalStreamer(5),
  bloom(6),
  verticalStreamer(7),
  reactive(8),
  sineWave(9),
  taiChi(10),
  gather(11),
  shuttle(12),
  twinFlowers(13),
  meteor(14),
  grid(15),
  wheel(16),
  tide(17),
  snake(18),
  circles(19),
  shootingStar(20),
  laser(21);

  final int value;
  const LightingMode(this.value);
}

class LightingConfig {
  final int type;
  final LightingMode mode;
  final int brightness;       // 0 to 4
  final int speed;            // 0 to 4
  final int direction;        // 1 = Left/Horizontal, 2 = Up/Vertical
  final int colorMode;        // 0 = Rainbow dynamic, 1 = Single color
  final int singleColorIndex; // 0 to 7
  final double hue;           // 0.0 to 360.0 degrees
  final double saturation;    // 0.0 to 100.0 percent
  final double value;         // 0.0 to 100.0 percent

  const LightingConfig({
    required this.type,
    required this.mode,
    required this.brightness,
    required this.speed,
    required this.direction,
    required this.colorMode,
    required this.singleColorIndex,
    required this.hue,
    required this.saturation,
    required this.value,
  });
}
```

---

## 4. Macro System Models

```dart
enum MacroActionType {
  mouseButton(1),
  keyboardKey(2),
  scrollVertical(3),
  scrollHorizontal(4);

  final int value;
  const MacroActionType(this.value);
}

class MacroAction {
  final String name;             // e.g. "A", "Ctrl", "Mouse L-Button", "Scroll Up"
  final int code;                // Key code or button mask
  final MacroActionType type;    // Action category
  final bool isPress;            // true = Down, false = Up
  int delay;                     // Milliseconds delay before next action (0 to 10,000)

  MacroAction({
    required this.name,
    required this.code,
    required this.type,
    required this.isPress,
    required this.delay,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'type': type.value,
    'action': isPress ? 1 : 2,
    'delay': delay,
  };
}

class MacroModel {
  final String name;             // e.g. "M0", "M1", "Sniper Burst"
  final List<MacroAction> actions;
  final int loopMode;            // 0=Once, 1=Hold, 2=UntilAny, 3=Toggle, 4=RepeatN

  MacroModel({
    required this.name,
    required this.actions,
    this.loopMode = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'list': actions.map((a) => a.toJson()).toList(),
    'loopMode': loopMode,
  };
}
```

---

## 5. Physical Keycap Layout Definition (`KeyLayoutData`)

Contains the physical geometry for the 61-key visualizer canvas:

```dart
class KeyGeometry {
  final int row;       // 0 to 4
  final int col;       // 0 to 13
  final double x;      // X unit coordinate (1.0 = standard 1u key width)
  final double y;      // Y unit coordinate
  final double w;      // Key width (1.0 = 1u, 1.25 = 1.25u, 2.25 = Enter, 6.25 = Space)
  final double h;      // Key height (1.0 = 1u)
  final int index;     // Hardware matrix index (0 to 73)
  final String name;   // Legend
  final int code;      // Default HID usage code

  const KeyGeometry({
    required this.row,
    required this.col,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.index,
    required this.name,
    required this.code,
  });
}
```
