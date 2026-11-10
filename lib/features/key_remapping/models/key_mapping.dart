import '../../../core/constants/key_codes.dart';

/// Categories for key remapping actions supported by MK1300 V2.
enum RemapCategory {
  basic('Basic Keys', 32),
  media('Media Controls', 48),
  mouse('Mouse Actions', 16),
  shortcut('Shortcuts & System', 32),
  hardware('Hardware Controls', 31),
  macro('Macros', 96),
  custom('Custom Combo', 255);

  final String label;
  final int defaultType;
  const RemapCategory(this.label, this.defaultType);
}

/// Catalog item representing an assignable remapping target.
class KeyRemapAction {
  final String name;
  final String code;
  final RemapCategory category;
  final int type;
  final int value1;
  final int value2;
  final int value3;
  final String? description;

  const KeyRemapAction({
    required this.name,
    required this.code,
    required this.category,
    required this.type,
    required this.value1,
    required this.value2,
    required this.value3,
    this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyRemapAction &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value1 == other.value1 &&
          value2 == other.value2 &&
          value3 == other.value3;

  @override
  int get hashCode => Object.hash(type, value1, value2, value3);
}

/// Catalog provider for all assignable remapping actions.
class KeyCatalog {
  KeyCatalog._();

  static List<KeyRemapAction> get basicActions => KeyCodes.basicKeys
      .where((k) => k.name.trim().isNotEmpty)
      .map((k) => KeyRemapAction(
            name: k.name,
            code: k.code,
            category: RemapCategory.basic,
            type: k.type,
            value1: k.value1,
            value2: k.value2,
            value3: k.value3,
          ))
      .toList();

  static List<KeyRemapAction> get mediaActions => KeyCodes.mediaKeys
      .map((k) => KeyRemapAction(
            name: k.name,
            code: k.code,
            category: RemapCategory.media,
            type: k.type,
            value1: k.value1,
            value2: k.value2,
            value3: k.value3,
          ))
      .toList();

  static List<KeyRemapAction> get mouseActions => KeyCodes.mouseKeys
      .map((k) => KeyRemapAction(
            name: k.name,
            code: k.code,
            category: RemapCategory.mouse,
            type: k.type,
            value1: k.value1,
            value2: k.value2,
            value3: k.value3,
          ))
      .toList();

  static List<KeyRemapAction> get shortcutActions => KeyCodes.shortcutKeys
      .map((k) => KeyRemapAction(
            name: k.name,
            code: k.code,
            category: RemapCategory.shortcut,
            type: k.type,
            value1: k.value1,
            value2: k.value2,
            value3: k.value3,
          ))
      .toList();

  static List<KeyRemapAction> get hardwareActions => KeyCodes.hardwareKeys
      .map((k) => KeyRemapAction(
            name: k.name,
            code: k.code,
            category: RemapCategory.hardware,
            type: k.type,
            value1: k.value1,
            value2: k.value2,
            value3: k.value3,
          ))
      .toList();

  static List<KeyRemapAction> get macroActions => KeyCodes.macroKeys
      .map((k) => KeyRemapAction(
            name: k.name,
            code: k.code,
            category: RemapCategory.macro,
            type: k.type,
            value1: k.value1,
            value2: k.value2,
            value3: k.value3,
          ))
      .toList();

  static List<KeyRemapAction> get allActions => [
        ...basicActions,
        ...mediaActions,
        ...mouseActions,
        ...shortcutActions,
        ...hardwareActions,
        ...macroActions,
      ];

  static List<KeyRemapAction> search(String query, {RemapCategory? category}) {
    final q = query.trim().toLowerCase();
    Iterable<KeyRemapAction> list = allActions;
    if (category != null) {
      list = list.where((a) => a.category == category);
    }
    if (q.isEmpty) return list.toList();
    return list.where((a) {
      return a.name.toLowerCase().contains(q) ||
          a.code.toLowerCase().contains(q) ||
          (a.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

/// Key mapping state model for a single keycap in a specific layer.
/// Tracks default factory assignment, hardware-confirmed assignment,
/// and local pending changes before hardware synchronization.
class KeyMapping {
  final int keyIndex;
  final String defaultName;
  final int defaultCode;
  final int defaultType;
  final int defaultCode1;
  final int defaultCode3;

  // Confirmed hardware state
  int confirmedType;
  int confirmedCode1;
  int confirmedCode2;
  int confirmedCode3;
  String confirmedName;

  // Local pending / active state
  int newType;
  int newCode1;
  int newCode2;
  int newCode3;
  String newName;
  String colorHex;

  KeyMapping({
    required this.keyIndex,
    required this.defaultName,
    required this.defaultCode,
    required this.defaultType,
    this.defaultCode1 = 0,
    this.defaultCode3 = 0,
    required this.confirmedType,
    required this.confirmedCode1,
    required this.confirmedCode2,
    required this.confirmedCode3,
    required this.confirmedName,
    required this.newType,
    required this.newCode1,
    required this.newCode2,
    required this.newCode3,
    required this.newName,
    required this.colorHex,
  });

  /// True if there are unapplied local changes different from confirmed hardware state.
  bool get isPendingChange =>
      newType != confirmedType ||
      newCode1 != confirmedCode1 ||
      newCode2 != confirmedCode2 ||
      newCode3 != confirmedCode3;

  /// True if current assignment differs from factory default.
  bool get isModifiedFromDefault =>
      newType != defaultType ||
      newCode1 != defaultCode1 ||
      newCode2 != defaultCode ||
      newCode3 != defaultCode3;

  /// Remap category of the currently pending/active assignment.
  RemapCategory get category {
    if (newType == KeyCodes.typeMacro) return RemapCategory.macro;
    if (newType == KeyCodes.typeMedia) return RemapCategory.media;
    if (newType == KeyCodes.typeMouse || newType == KeyCodes.typeMouseMove) {
      return RemapCategory.mouse;
    }
    if (newType == KeyCodes.typeHardware) return RemapCategory.hardware;
    if (newType == KeyCodes.typePower) return RemapCategory.shortcut;
    if (newType == KeyCodes.typeCustomCombo) return RemapCategory.custom;
    if (newType == KeyCodes.typeStandard && newCode1 != 0) {
      return RemapCategory.shortcut;
    }
    return RemapCategory.basic;
  }

  /// Assigns a catalog action to this key locally.
  void assignAction(KeyRemapAction action) {
    newType = action.type;
    newCode1 = action.value1;
    newCode2 = action.value2;
    newCode3 = action.value3;
    newName = action.name;
  }

  /// Assigns explicit raw tuple parameters to this key locally.
  void assignManual({
    required int type,
    required int code1,
    required int code2,
    required int code3,
    required String name,
  }) {
    newType = type;
    newCode1 = code1;
    newCode2 = code2;
    newCode3 = code3;
    newName = name;
  }

  /// Updates state from hardware readback, marking state as confirmed.
  void updateFromHardware({
    required int type,
    required int code1,
    required int code2,
    required int code3,
    required String name,
  }) {
    confirmedType = type;
    confirmedCode1 = code1;
    confirmedCode2 = code2;
    confirmedCode3 = code3;
    confirmedName = name;
    newType = type;
    newCode1 = code1;
    newCode2 = code2;
    newCode3 = code3;
    newName = name;
  }

  /// Commits current local state as confirmed hardware state.
  void confirmPending() {
    confirmedType = newType;
    confirmedCode1 = newCode1;
    confirmedCode2 = newCode2;
    confirmedCode3 = newCode3;
    confirmedName = newName;
  }

  /// Reverts uncommitted local changes back to confirmed hardware state.
  void revertPending() {
    newType = confirmedType;
    newCode1 = confirmedCode1;
    newCode2 = confirmedCode2;
    newCode3 = confirmedCode3;
    newName = confirmedName;
  }

  /// Resets local state back to factory default.
  void resetToDefault() {
    newType = defaultType;
    newCode1 = defaultCode1;
    newCode2 = defaultCode;
    newCode3 = defaultCode3;
    newName = defaultName;
  }

  /// Factory creating default 1:1 mapping from [KeyGeometry], supporting Layer 0 and Layer 1 defaults.
  factory KeyMapping.fromGeometry(dynamic geo, {int layer = 0}) {
    int defType = geo.defaultType as int? ?? 32;
    int defCode = geo.defaultCode as int? ?? 0;
    String defName = geo.name as String? ?? 'Key';

    // Apply recovered secondary Fn Layer defaults for 60% compact layout
    if (layer == 1) {
      final fnDef = _resolveFnDefault(geo.index as int, defName, defCode);
      defType = fnDef.$1;
      defCode = fnDef.$2;
      defName = fnDef.$3;
    }

    return KeyMapping(
      keyIndex: geo.index as int,
      defaultName: defName,
      defaultCode: defCode,
      defaultType: defType,
      defaultCode1: 0,
      defaultCode3: 0,
      confirmedType: defType,
      confirmedCode1: 0,
      confirmedCode2: defCode,
      confirmedCode3: 0,
      confirmedName: defName,
      newType: defType,
      newCode1: 0,
      newCode2: defCode,
      newCode3: 0,
      newName: defName,
      colorHex: '#00C8FF',
    );
  }

  static (int type, int code, String name) _resolveFnDefault(int index, String baseName, int baseCode) {
    switch (index) {
      case 0:  return (32, 53, '`');        // Esc -> `
      case 1:  return (32, 58, 'F1');       // 1 -> F1
      case 2:  return (32, 59, 'F2');       // 2 -> F2
      case 3:  return (32, 60, 'F3');       // 3 -> F3
      case 4:  return (32, 61, 'F4');       // 4 -> F4
      case 5:  return (32, 62, 'F5');       // 5 -> F5
      case 6:  return (32, 63, 'F6');       // 6 -> F6
      case 7:  return (32, 64, 'F7');       // 7 -> F7
      case 8:  return (32, 65, 'F8');       // 8 -> F8
      case 9:  return (32, 66, 'F9');       // 9 -> F9
      case 10: return (32, 67, 'F10');      // 0 -> F10
      case 11: return (32, 68, 'F11');      // - -> F11
      case 12: return (32, 69, 'F12');      // + -> F12
      case 13: return (32, 76, 'Delete');   // Backspace -> Del
      case 17: return (32, 82, 'Up');       // W -> Up
      case 31: return (32, 80, 'Left');     // A -> Left
      case 32: return (32, 81, 'Down');     // S -> Down
      case 33: return (32, 79, 'Right');    // D -> Right
      case 26: return (32, 70, 'Print');    // [ -> PrintScreen
      case 27: return (32, 71, 'Scroll');   // ] -> ScrollLock
      case 28: return (32, 72, 'Pause');    // \ -> Pause
      case 40: return (32, 75, 'PageUp');   // ; -> PgUp
      case 41: return (32, 78, 'PageDown'); // ' -> PgDn
      case 55: return (32, 73, 'Insert');   // . -> Ins
      case 56: return (32, 76, 'Delete');   // / -> Del
      default: return (32, baseCode, baseName);
    }
  }

  KeyMapping copyWith({
    int? confirmedType,
    int? confirmedCode1,
    int? confirmedCode2,
    int? confirmedCode3,
    String? confirmedName,
    int? newType,
    int? newCode1,
    int? newCode2,
    int? newCode3,
    String? newName,
    String? colorHex,
  }) {
    return KeyMapping(
      keyIndex: keyIndex,
      defaultName: defaultName,
      defaultCode: defaultCode,
      defaultType: defaultType,
      defaultCode1: defaultCode1,
      defaultCode3: defaultCode3,
      confirmedType: confirmedType ?? this.confirmedType,
      confirmedCode1: confirmedCode1 ?? this.confirmedCode1,
      confirmedCode2: confirmedCode2 ?? this.confirmedCode2,
      confirmedCode3: confirmedCode3 ?? this.confirmedCode3,
      confirmedName: confirmedName ?? this.confirmedName,
      newType: newType ?? this.newType,
      newCode1: newCode1 ?? this.newCode1,
      newCode2: newCode2 ?? this.newCode2,
      newCode3: newCode3 ?? this.newCode3,
      newName: newName ?? this.newName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
