/// Key mapping state model for a single keycap.
class KeyMapping {
  final int keyIndex;
  final String defaultName;
  final int defaultCode;
  final int defaultType;

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
    required this.newType,
    required this.newCode1,
    required this.newCode2,
    required this.newCode3,
    required this.newName,
    required this.colorHex,
  });

  /// Factory creating default 1:1 mapping from [KeyGeometry].
  factory KeyMapping.fromGeometry(dynamic geo) {
    return KeyMapping(
      keyIndex: geo.index,
      defaultName: geo.name,
      defaultCode: geo.defaultCode,
      defaultType: geo.defaultType,
      newType: geo.defaultType,
      newCode1: 0,
      newCode2: geo.defaultCode,
      newCode3: 0,
      newName: geo.name,
      colorHex: '#00C8FF',
    );
  }

  KeyMapping copyWith({
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
      newType: newType ?? this.newType,
      newCode1: newCode1 ?? this.newCode1,
      newCode2: newCode2 ?? this.newCode2,
      newCode3: newCode3 ?? this.newCode3,
      newName: newName ?? this.newName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
