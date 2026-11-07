enum MacroActionType {
  mouseButton(1),
  keyboardKey(2),
  scrollVertical(3),
  scrollHorizontal(4);

  final int value;
  const MacroActionType(this.value);

  static MacroActionType fromValue(int val) {
    for (final t in values) {
      if (t.value == val) return t;
    }
    return keyboardKey;
  }
}

/// Represents a single recorded keystroke or mouse event in a macro.
class MacroAction {
  String name;
  int code;
  MacroActionType type;
  bool isPress; // true = KeyDown/MouseDown, false = KeyUp/MouseUp
  int delay;    // Milliseconds delay before next action

  MacroAction({
    required this.name,
    required this.code,
    required this.type,
    required this.isPress,
    required this.delay,
  });

  factory MacroAction.fromJson(Map<String, dynamic> json) {
    return MacroAction(
      name: json['name'] as String? ?? 'Key',
      code: json['code'] as int? ?? 0,
      type: MacroActionType.fromValue(json['type'] as int? ?? 2),
      isPress: (json['action'] as int? ?? 1) == 1,
      delay: json['delay'] as int? ?? 50,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'type': type.value,
    'action': isPress ? 1 : 2,
    'delay': delay,
  };
}
