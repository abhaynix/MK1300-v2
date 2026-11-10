/// Definition of all key codes, categories, and labels recovered from MK1300 V2.
class KeyCodeItem {
  final String name;
  final String code;
  final String? langId;
  final int type;
  final int value1;
  final int value2;
  final int value3;

  const KeyCodeItem({
    required this.name,
    required this.code,
    this.langId,
    required this.type,
    required this.value1,
    required this.value2,
    required this.value3,
  });
}

class KeyCodes {
  KeyCodes._();

  // Key Category Types
  static const int typeMouse = 16;       // 0x10
  static const int typeMouseMove = 17;   // 0x11
  static const int typeHardware = 31;    // 0x1F (lighting/profile/lock)
  static const int typeStandard = 32;    // 0x20
  static const int typeMedia = 48;       // 0x30
  static const int typePower = 64;       // 0x40
  static const int typeMacro = 96;       // 0x60
  static const int typeCustomCombo = 255;// 0xFF

  /// Standard HID Keyboard Key Definitions
  static const List<KeyCodeItem> basicKeys = [
    KeyCodeItem(name: 'Esc', code: 'KC_ESC', type: typeStandard, value1: 0, value2: 41, value3: 0),
    KeyCodeItem(name: 'F1', code: 'KC_F1', type: typeStandard, value1: 0, value2: 58, value3: 0),
    KeyCodeItem(name: 'F2', code: 'KC_F2', type: typeStandard, value1: 0, value2: 59, value3: 0),
    KeyCodeItem(name: 'F3', code: 'KC_F3', type: typeStandard, value1: 0, value2: 60, value3: 0),
    KeyCodeItem(name: 'F4', code: 'KC_F4', type: typeStandard, value1: 0, value2: 61, value3: 0),
    KeyCodeItem(name: 'F5', code: 'KC_F5', type: typeStandard, value1: 0, value2: 62, value3: 0),
    KeyCodeItem(name: 'F6', code: 'KC_F6', type: typeStandard, value1: 0, value2: 63, value3: 0),
    KeyCodeItem(name: 'F7', code: 'KC_F7', type: typeStandard, value1: 0, value2: 64, value3: 0),
    KeyCodeItem(name: 'F8', code: 'KC_F8', type: typeStandard, value1: 0, value2: 65, value3: 0),
    KeyCodeItem(name: 'F9', code: 'KC_F9', type: typeStandard, value1: 0, value2: 66, value3: 0),
    KeyCodeItem(name: 'F10', code: 'KC_F10', type: typeStandard, value1: 0, value2: 67, value3: 0),
    KeyCodeItem(name: 'F11', code: 'KC_F11', type: typeStandard, value1: 0, value2: 68, value3: 0),
    KeyCodeItem(name: 'F12', code: 'KC_F12', type: typeStandard, value1: 0, value2: 69, value3: 0),
    KeyCodeItem(name: 'Print', code: 'KC_PSCR', type: typeStandard, value1: 0, value2: 70, value3: 0),
    KeyCodeItem(name: 'Scroll', code: 'KC_SLCK', type: typeStandard, value1: 0, value2: 71, value3: 0),
    KeyCodeItem(name: 'Pause', code: 'KC_PAUS', type: typeStandard, value1: 0, value2: 72, value3: 0),
    KeyCodeItem(name: '`', code: 'KC_GRV', type: typeStandard, value1: 0, value2: 53, value3: 0),
    KeyCodeItem(name: '1', code: 'KC_1', type: typeStandard, value1: 0, value2: 30, value3: 0),
    KeyCodeItem(name: '2', code: 'KC_2', type: typeStandard, value1: 0, value2: 31, value3: 0),
    KeyCodeItem(name: '3', code: 'KC_3', type: typeStandard, value1: 0, value2: 32, value3: 0),
    KeyCodeItem(name: '4', code: 'KC_4', type: typeStandard, value1: 0, value2: 33, value3: 0),
    KeyCodeItem(name: '5', code: 'KC_5', type: typeStandard, value1: 0, value2: 34, value3: 0),
    KeyCodeItem(name: '6', code: 'KC_6', type: typeStandard, value1: 0, value2: 35, value3: 0),
    KeyCodeItem(name: '7', code: 'KC_7', type: typeStandard, value1: 0, value2: 36, value3: 0),
    KeyCodeItem(name: '8', code: 'KC_8', type: typeStandard, value1: 0, value2: 37, value3: 0),
    KeyCodeItem(name: '9', code: 'KC_9', type: typeStandard, value1: 0, value2: 38, value3: 0),
    KeyCodeItem(name: '0', code: 'KC_0', type: typeStandard, value1: 0, value2: 39, value3: 0),
    KeyCodeItem(name: '-', code: 'KC_MINS', type: typeStandard, value1: 0, value2: 45, value3: 0),
    KeyCodeItem(name: '=', code: 'KC_EQL', type: typeStandard, value1: 0, value2: 46, value3: 0),
    KeyCodeItem(name: 'Backspace', code: 'KC_BSPC', type: typeStandard, value1: 0, value2: 42, value3: 0),
    KeyCodeItem(name: 'Tab', code: 'KC_TAB', type: typeStandard, value1: 0, value2: 43, value3: 0),
    KeyCodeItem(name: 'Q', code: 'KC_Q', type: typeStandard, value1: 0, value2: 20, value3: 0),
    KeyCodeItem(name: 'W', code: 'KC_W', type: typeStandard, value1: 0, value2: 26, value3: 0),
    KeyCodeItem(name: 'E', code: 'KC_E', type: typeStandard, value1: 0, value2: 8, value3: 0),
    KeyCodeItem(name: 'R', code: 'KC_R', type: typeStandard, value1: 0, value2: 21, value3: 0),
    KeyCodeItem(name: 'T', code: 'KC_T', type: typeStandard, value1: 0, value2: 23, value3: 0),
    KeyCodeItem(name: 'Y', code: 'KC_Y', type: typeStandard, value1: 0, value2: 28, value3: 0),
    KeyCodeItem(name: 'U', code: 'KC_U', type: typeStandard, value1: 0, value2: 24, value3: 0),
    KeyCodeItem(name: 'I', code: 'KC_I', type: typeStandard, value1: 0, value2: 12, value3: 0),
    KeyCodeItem(name: 'O', code: 'KC_O', type: typeStandard, value1: 0, value2: 18, value3: 0),
    KeyCodeItem(name: 'P', code: 'KC_P', type: typeStandard, value1: 0, value2: 19, value3: 0),
    KeyCodeItem(name: '[', code: 'KC_LBRC', type: typeStandard, value1: 0, value2: 47, value3: 0),
    KeyCodeItem(name: ']', code: 'KC_RBRC', type: typeStandard, value1: 0, value2: 48, value3: 0),
    KeyCodeItem(name: '\\', code: 'KC_BSLS', type: typeStandard, value1: 0, value2: 49, value3: 0),
    KeyCodeItem(name: 'Caps Lock', code: 'KC_CAPS', type: typeStandard, value1: 0, value2: 57, value3: 0),
    KeyCodeItem(name: 'A', code: 'KC_A', type: typeStandard, value1: 0, value2: 4, value3: 0),
    KeyCodeItem(name: 'S', code: 'KC_S', type: typeStandard, value1: 0, value2: 22, value3: 0),
    KeyCodeItem(name: 'D', code: 'KC_D', type: typeStandard, value1: 0, value2: 7, value3: 0),
    KeyCodeItem(name: 'F', code: 'KC_F', type: typeStandard, value1: 0, value2: 9, value3: 0),
    KeyCodeItem(name: 'G', code: 'KC_G', type: typeStandard, value1: 0, value2: 10, value3: 0),
    KeyCodeItem(name: 'H', code: 'KC_H', type: typeStandard, value1: 0, value2: 11, value3: 0),
    KeyCodeItem(name: 'J', code: 'KC_J', type: typeStandard, value1: 0, value2: 13, value3: 0),
    KeyCodeItem(name: 'K', code: 'KC_K', type: typeStandard, value1: 0, value2: 14, value3: 0),
    KeyCodeItem(name: 'L', code: 'KC_L', type: typeStandard, value1: 0, value2: 15, value3: 0),
    KeyCodeItem(name: ';', code: 'KC_SCLN', type: typeStandard, value1: 0, value2: 51, value3: 0),
    KeyCodeItem(name: '\'', code: 'KC_QUOT', type: typeStandard, value1: 0, value2: 52, value3: 0),
    KeyCodeItem(name: 'Enter', code: 'KC_ENT', type: typeStandard, value1: 0, value2: 40, value3: 0),
    KeyCodeItem(name: 'Shift', code: 'KC_LSFT', type: typeStandard, value1: 0, value2: 225, value3: 0),
    KeyCodeItem(name: 'Z', code: 'KC_Z', type: typeStandard, value1: 0, value2: 29, value3: 0),
    KeyCodeItem(name: 'X', code: 'KC_X', type: typeStandard, value1: 0, value2: 27, value3: 0),
    KeyCodeItem(name: 'C', code: 'KC_C', type: typeStandard, value1: 0, value2: 6, value3: 0),
    KeyCodeItem(name: 'V', code: 'KC_V', type: typeStandard, value1: 0, value2: 25, value3: 0),
    KeyCodeItem(name: 'B', code: 'KC_B', type: typeStandard, value1: 0, value2: 5, value3: 0),
    KeyCodeItem(name: 'N', code: 'KC_N', type: typeStandard, value1: 0, value2: 17, value3: 0),
    KeyCodeItem(name: 'M', code: 'KC_M', type: typeStandard, value1: 0, value2: 16, value3: 0),
    KeyCodeItem(name: '<', code: 'KC_COMM', type: typeStandard, value1: 0, value2: 54, value3: 0),
    KeyCodeItem(name: '>', code: 'KC_DOT', type: typeStandard, value1: 0, value2: 55, value3: 0),
    KeyCodeItem(name: '?', code: 'KC_SLSH', type: typeStandard, value1: 0, value2: 56, value3: 0),
    KeyCodeItem(name: 'Ctrl', code: 'KC_LCTL', type: typeStandard, value1: 0, value2: 224, value3: 0),
    KeyCodeItem(name: 'Win', code: 'KC_LGUI', type: typeStandard, value1: 0, value2: 227, value3: 0),
    KeyCodeItem(name: 'Alt', code: 'KC_LALT', type: typeStandard, value1: 0, value2: 226, value3: 0),
    KeyCodeItem(name: 'Space', code: 'KC_SPC', type: typeStandard, value1: 0, value2: 44, value3: 0),
    KeyCodeItem(name: 'App', code: 'KC_APP', type: typeStandard, value1: 0, value2: 101, value3: 0),
    KeyCodeItem(name: 'Insert', code: 'KC_INS', type: typeStandard, value1: 0, value2: 73, value3: 0),
    KeyCodeItem(name: 'Delete', code: 'KC_DEL', type: typeStandard, value1: 0, value2: 76, value3: 0),
    KeyCodeItem(name: 'Home', code: 'KC_HOME', type: typeStandard, value1: 0, value2: 74, value3: 0),
    KeyCodeItem(name: 'End', code: 'KC_END', type: typeStandard, value1: 0, value2: 77, value3: 0),
    KeyCodeItem(name: 'PageUp', code: 'KC_PGUP', type: typeStandard, value1: 0, value2: 75, value3: 0),
    KeyCodeItem(name: 'PageDown', code: 'KC_PGDN', type: typeStandard, value1: 0, value2: 78, value3: 0),
    KeyCodeItem(name: 'Up', code: 'KC_UP', type: typeStandard, value1: 0, value2: 82, value3: 0),
    KeyCodeItem(name: 'Down', code: 'KC_DOWN', type: typeStandard, value1: 0, value2: 81, value3: 0),
    KeyCodeItem(name: 'Left', code: 'KC_LEFT', type: typeStandard, value1: 0, value2: 80, value3: 0),
    KeyCodeItem(name: 'Right', code: 'KC_RGHT', type: typeStandard, value1: 0, value2: 79, value3: 0),
  ];

  /// Media & Consumer Keys
  static const List<KeyCodeItem> mediaKeys = [
    KeyCodeItem(name: 'Volume +', code: 'KC_VOLU', langId: '60001', type: typeMedia, value1: 233, value2: 0, value3: 0),
    KeyCodeItem(name: 'Volume -', code: 'KC_VOLD', langId: '60002', type: typeMedia, value1: 234, value2: 0, value3: 0),
    KeyCodeItem(name: 'Mute', code: 'KC_MUTE', langId: '60003', type: typeMedia, value1: 226, value2: 0, value3: 0),
    KeyCodeItem(name: 'Play/Pause', code: 'KC_MPLY', langId: '60004', type: typeMedia, value1: 205, value2: 0, value3: 0),
    KeyCodeItem(name: 'Stop', code: 'KC_MSTP', langId: '60005', type: typeMedia, value1: 183, value2: 0, value3: 0),
    KeyCodeItem(name: 'Prev Track', code: 'KC_MPRV', langId: '60006', type: typeMedia, value1: 182, value2: 0, value3: 0),
    KeyCodeItem(name: 'Next Track', code: 'KC_MNXT', langId: '60007', type: typeMedia, value1: 181, value2: 0, value3: 0),
    KeyCodeItem(name: 'Homepage', code: 'KC_HOMEPAGE', langId: '60009', type: typeMedia, value1: 35, value2: 2, value3: 0),
    KeyCodeItem(name: 'Web Refresh', code: 'KC_WREF', langId: '60010', type: typeMedia, value1: 39, value2: 2, value3: 0),
    KeyCodeItem(name: 'Web Stop', code: 'KC_WSTP', langId: '60011', type: typeMedia, value1: 38, value2: 2, value3: 0),
    KeyCodeItem(name: 'Web Forward', code: 'KC_WFWD', langId: '60012', type: typeMedia, value1: 37, value2: 2, value3: 0),
    KeyCodeItem(name: 'Web Backward', code: 'KC_WBAK', langId: '60013', type: typeMedia, value1: 36, value2: 2, value3: 0),
    KeyCodeItem(name: 'Web Favorites', code: 'KC_WFAV', langId: '60014', type: typeMedia, value1: 42, value2: 2, value3: 0),
    KeyCodeItem(name: 'Web Search', code: 'KC_WSCH', langId: '60015', type: typeMedia, value1: 33, value2: 2, value3: 0),
    KeyCodeItem(name: 'Calculator', code: 'KC_CALC', langId: '60016', type: typeMedia, value1: 146, value2: 1, value3: 0),
    KeyCodeItem(name: 'My Computer', code: 'KC_MYPC', langId: '60017', type: typeMedia, value1: 148, value2: 1, value3: 0),
    KeyCodeItem(name: 'Mail', code: 'KC_MAIL', langId: '60018', type: typeMedia, value1: 138, value2: 1, value3: 0),
  ];

  /// Mouse Keys
  static const List<KeyCodeItem> mouseKeys = [
    KeyCodeItem(name: 'Left Button', code: 'L-BUTTON', langId: '70001', type: typeMouse, value1: 1, value2: 0, value3: 0),
    KeyCodeItem(name: 'Right Button', code: 'R-BUTTON', langId: '70003', type: typeMouse, value1: 2, value2: 0, value3: 0),
    KeyCodeItem(name: 'Middle Button', code: 'M-BUTTON', langId: '70002', type: typeMouse, value1: 4, value2: 0, value3: 0),
    KeyCodeItem(name: 'Forward', code: 'Forward', langId: '70004', type: typeMouse, value1: 16, value2: 0, value3: 0),
    KeyCodeItem(name: 'Backward', code: 'Backward', langId: '70005', type: typeMouse, value1: 8, value2: 0, value3: 0),
    KeyCodeItem(name: 'Wheel Up', code: 'UpWheel', langId: '70006', type: typeMouse, value1: 0, value2: 0, value3: 1),
    KeyCodeItem(name: 'Wheel Down', code: 'DownWheel', langId: '70007', type: typeMouse, value1: 0, value2: 0, value3: 255),
  ];

  /// Shortcut Keys
  static const List<KeyCodeItem> shortcutKeys = [
    KeyCodeItem(name: 'Ctrl + A', code: 'CTRL_A', langId: '80001', type: typeStandard, value1: 1, value2: 4, value3: 0),
    KeyCodeItem(name: 'Ctrl + C', code: 'CTRL_C', langId: '80002', type: typeStandard, value1: 1, value2: 6, value3: 0),
    KeyCodeItem(name: 'Ctrl + V', code: 'CTRL_V', langId: '80003', type: typeStandard, value1: 1, value2: 25, value3: 0),
    KeyCodeItem(name: 'Ctrl + S', code: 'CTRL_S', langId: '80004', type: typeStandard, value1: 1, value2: 22, value3: 0),
    KeyCodeItem(name: 'Ctrl + Z', code: 'CTRL_Z', langId: '80006', type: typeStandard, value1: 1, value2: 29, value3: 0),
    KeyCodeItem(name: 'Power', code: 'POWER', langId: '80010', type: typePower, value1: 1, value2: 0, value3: 0),
    KeyCodeItem(name: 'Sleep', code: 'SLEEP', langId: '80011', type: typePower, value1: 2, value2: 0, value3: 0),
    KeyCodeItem(name: 'Wakeup', code: 'WAKEUP', langId: '80012', type: typePower, value1: 4, value2: 0, value3: 0),
  ];

  /// Hardware Function Keys
  static const List<KeyCodeItem> hardwareKeys = [
    KeyCodeItem(name: 'Light Switch', code: 'LIGHT_SW', langId: '80020', type: typeHardware, value1: 0, value2: 0, value3: 0),
    KeyCodeItem(name: 'Light Effect', code: 'LIGHT_FX', langId: '80021', type: typeHardware, value1: 1, value2: 0, value3: 0),
    KeyCodeItem(name: 'Brightness +', code: 'BRT_INC', langId: '80025', type: typeHardware, value1: 1, value2: 0, value3: 0),
    KeyCodeItem(name: 'Brightness -', code: 'BRT_DEC', langId: '80026', type: typeHardware, value1: 2, value2: 0, value3: 0),
    KeyCodeItem(name: 'Speed +', code: 'SPD_INC', langId: '80022', type: typeHardware, value1: 5, value2: 0, value3: 0),
    KeyCodeItem(name: 'Speed -', code: 'SPD_DEC', langId: '80023', type: typeHardware, value1: 6, value2: 0, value3: 0),
    KeyCodeItem(name: 'Color Switch', code: 'CLR_SW', langId: '80024', type: typeHardware, value1: 4, value2: 0, value3: 0),
    KeyCodeItem(name: 'Profile Switch', code: 'PROF_SW', langId: '80040', type: typeHardware, value1: 19, value2: 0, value3: 0),
    KeyCodeItem(name: 'Lock Keyboard', code: 'LOCK_KB', langId: '80042', type: typeHardware, value1: 25, value2: 0, value3: 0),
  ];

  /// Macro Trigger Keys (Slots M0 through M15)
  static final List<KeyCodeItem> macroKeys = List.generate(
    16,
    (i) => KeyCodeItem(
      name: 'M$i',
      code: 'MACRO($i)',
      type: typeMacro,
      value1: i,
      value2: 1,
      value3: 0,
    ),
  );

  /// Resolves human-readable name from type and code parameters.
  static String resolveKeyName(int type, int code1, int code2, int code3) {
    if (type == typeMacro) {
      return 'M$code1';
    }
    for (final key in basicKeys) {
      if (key.type == type && key.value2 == code2) return key.name;
    }
    for (final key in mediaKeys) {
      if (key.type == type && key.value1 == code1) return key.name;
    }
    for (final key in mouseKeys) {
      if (key.type == type && key.value1 == code1) return key.name;
    }
    for (final key in shortcutKeys) {
      if (key.type == type && key.value1 == code1 && key.value2 == code2) return key.name;
    }
    for (final key in hardwareKeys) {
      if (key.type == type && key.value1 == code1) return key.name;
    }
    return code2 > 0 ? 'Key $code2' : 'None';
  }
}
