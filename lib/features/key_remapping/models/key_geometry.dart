import 'dart:convert';
import 'package:flutter/services.dart';

/// Physical geometry and switch properties for an individual key.
class KeyGeometry {
  final int row;
  final int col;
  final double x;
  final double y;
  final double w;
  final double h;
  final int index;
  final String name;
  final int defaultCode;
  final int defaultType;

  const KeyGeometry({
    required this.row,
    required this.col,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.index,
    required this.name,
    required this.defaultCode,
    this.defaultType = 32,
  });

  /// Factory constructor to parse a key object directly from layout JSON.
  factory KeyGeometry.fromJson(Map<String, dynamic> json) {
    return KeyGeometry(
      row: (json['row'] as num).toInt(),
      col: (json['col'] as num).toInt(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      w: (json['w'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      index: (json['index'] as num).toInt(),
      name: json['name'] as String? ?? 'Key',
      defaultCode: (json['code'] as num?)?.toInt() ?? 0,
      defaultType: (json['type'] as num?)?.toInt() ?? 32,
    );
  }

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'index': index,
    'name': name,
    'code': defaultCode,
    'type': defaultType,
  };

  /// Parses layout JSON string and extracts the active keys list.
  /// Gracefully returns [fallbackLayout61] if data is malformed or missing.
  static List<KeyGeometry> parseLayout(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
      final layouts = data['layouts'] as Map<String, dynamic>?;
      if (layouts == null) return fallbackLayout61;

      final keysList = layouts['keys'] as List<dynamic>?;
      if (keysList == null || keysList.isEmpty) return fallbackLayout61;

      return keysList.map((k) => KeyGeometry.fromJson(k as Map<String, dynamic>)).toList();
    } catch (_) {
      return fallbackLayout61;
    }
  }

  /// Synchronous fallback layout representing the exact 61 keys from assets/data/36ae_fe12.json.
  static const List<KeyGeometry> fallbackLayout61 = [
    // Row 0
    KeyGeometry(row: 0, col: 0, x: 0.0, y: 0.0, w: 1.0, h: 1.0, index: 0, name: 'Esc', defaultCode: 41),
    KeyGeometry(row: 0, col: 1, x: 1.0, y: 0.0, w: 1.0, h: 1.0, index: 1, name: '1', defaultCode: 30),
    KeyGeometry(row: 0, col: 2, x: 2.0, y: 0.0, w: 1.0, h: 1.0, index: 2, name: '2', defaultCode: 31),
    KeyGeometry(row: 0, col: 3, x: 3.0, y: 0.0, w: 1.0, h: 1.0, index: 3, name: '3', defaultCode: 32),
    KeyGeometry(row: 0, col: 4, x: 4.0, y: 0.0, w: 1.0, h: 1.0, index: 4, name: '4', defaultCode: 33),
    KeyGeometry(row: 0, col: 5, x: 5.0, y: 0.0, w: 1.0, h: 1.0, index: 5, name: '5', defaultCode: 34),
    KeyGeometry(row: 0, col: 6, x: 6.0, y: 0.0, w: 1.0, h: 1.0, index: 6, name: '6', defaultCode: 35),
    KeyGeometry(row: 0, col: 7, x: 7.0, y: 0.0, w: 1.0, h: 1.0, index: 7, name: '7', defaultCode: 36),
    KeyGeometry(row: 0, col: 8, x: 8.0, y: 0.0, w: 1.0, h: 1.0, index: 8, name: '8', defaultCode: 37),
    KeyGeometry(row: 0, col: 9, x: 9.0, y: 0.0, w: 1.0, h: 1.0, index: 9, name: '9', defaultCode: 38),
    KeyGeometry(row: 0, col: 10, x: 10.0, y: 0.0, w: 1.0, h: 1.0, index: 10, name: '0', defaultCode: 39),
    KeyGeometry(row: 0, col: 11, x: 11.0, y: 0.0, w: 1.0, h: 1.0, index: 11, name: '-', defaultCode: 45),
    KeyGeometry(row: 0, col: 12, x: 12.0, y: 0.0, w: 1.0, h: 1.0, index: 12, name: '+', defaultCode: 46),
    KeyGeometry(row: 0, col: 13, x: 13.0, y: 0.0, w: 2.0, h: 1.0, index: 13, name: 'Back', defaultCode: 42),

    // Row 1
    KeyGeometry(row: 1, col: 0, x: 0.0, y: 1.0, w: 1.5, h: 1.0, index: 15, name: 'Tab', defaultCode: 43),
    KeyGeometry(row: 1, col: 1, x: 1.5, y: 1.0, w: 1.0, h: 1.0, index: 16, name: 'Q', defaultCode: 20),
    KeyGeometry(row: 1, col: 2, x: 2.5, y: 1.0, w: 1.0, h: 1.0, index: 17, name: 'W', defaultCode: 26),
    KeyGeometry(row: 1, col: 3, x: 3.5, y: 1.0, w: 1.0, h: 1.0, index: 18, name: 'E', defaultCode: 8),
    KeyGeometry(row: 1, col: 4, x: 4.5, y: 1.0, w: 1.0, h: 1.0, index: 19, name: 'R', defaultCode: 21),
    KeyGeometry(row: 1, col: 5, x: 5.5, y: 1.0, w: 1.0, h: 1.0, index: 20, name: 'T', defaultCode: 23),
    KeyGeometry(row: 1, col: 6, x: 6.5, y: 1.0, w: 1.0, h: 1.0, index: 21, name: 'Y', defaultCode: 28),
    KeyGeometry(row: 1, col: 7, x: 7.5, y: 1.0, w: 1.0, h: 1.0, index: 22, name: 'U', defaultCode: 24),
    KeyGeometry(row: 1, col: 8, x: 8.5, y: 1.0, w: 1.0, h: 1.0, index: 23, name: 'I', defaultCode: 12),
    KeyGeometry(row: 1, col: 9, x: 9.5, y: 1.0, w: 1.0, h: 1.0, index: 24, name: 'O', defaultCode: 18),
    KeyGeometry(row: 1, col: 10, x: 10.5, y: 1.0, w: 1.0, h: 1.0, index: 25, name: 'P', defaultCode: 19),
    KeyGeometry(row: 1, col: 11, x: 11.5, y: 1.0, w: 1.0, h: 1.0, index: 26, name: '[', defaultCode: 47),
    KeyGeometry(row: 1, col: 12, x: 12.5, y: 1.0, w: 1.0, h: 1.0, index: 27, name: ']', defaultCode: 48),
    KeyGeometry(row: 1, col: 13, x: 13.5, y: 1.0, w: 1.5, h: 1.0, index: 28, name: '\\', defaultCode: 49),

    // Row 2
    KeyGeometry(row: 2, col: 0, x: 0.0, y: 2.0, w: 1.75, h: 1.0, index: 30, name: 'Caps', defaultCode: 57),
    KeyGeometry(row: 2, col: 1, x: 1.75, y: 2.0, w: 1.0, h: 1.0, index: 31, name: 'A', defaultCode: 4),
    KeyGeometry(row: 2, col: 2, x: 2.75, y: 2.0, w: 1.0, h: 1.0, index: 32, name: 'S', defaultCode: 22),
    KeyGeometry(row: 2, col: 3, x: 3.75, y: 2.0, w: 1.0, h: 1.0, index: 33, name: 'D', defaultCode: 7),
    KeyGeometry(row: 2, col: 4, x: 4.75, y: 2.0, w: 1.0, h: 1.0, index: 34, name: 'F', defaultCode: 9),
    KeyGeometry(row: 2, col: 5, x: 5.75, y: 2.0, w: 1.0, h: 1.0, index: 35, name: 'G', defaultCode: 10),
    KeyGeometry(row: 2, col: 6, x: 6.75, y: 2.0, w: 1.0, h: 1.0, index: 36, name: 'H', defaultCode: 11),
    KeyGeometry(row: 2, col: 7, x: 7.75, y: 2.0, w: 1.0, h: 1.0, index: 37, name: 'J', defaultCode: 13),
    KeyGeometry(row: 2, col: 8, x: 8.75, y: 2.0, w: 1.0, h: 1.0, index: 38, name: 'K', defaultCode: 14),
    KeyGeometry(row: 2, col: 9, x: 9.75, y: 2.0, w: 1.0, h: 1.0, index: 39, name: 'L', defaultCode: 15),
    KeyGeometry(row: 2, col: 10, x: 10.75, y: 2.0, w: 1.0, h: 1.0, index: 40, name: ';', defaultCode: 51),
    KeyGeometry(row: 2, col: 11, x: 11.75, y: 2.0, w: 1.0, h: 1.0, index: 41, name: '\'', defaultCode: 52),
    KeyGeometry(row: 2, col: 13, x: 12.75, y: 2.0, w: 2.25, h: 1.0, index: 43, name: 'Enter', defaultCode: 40),

    // Row 3
    KeyGeometry(row: 3, col: 0, x: 0.0, y: 3.0, w: 2.25, h: 1.0, index: 45, name: 'Shift', defaultCode: 225),
    KeyGeometry(row: 3, col: 2, x: 2.25, y: 3.0, w: 1.0, h: 1.0, index: 47, name: 'Z', defaultCode: 29),
    KeyGeometry(row: 3, col: 3, x: 3.25, y: 3.0, w: 1.0, h: 1.0, index: 48, name: 'X', defaultCode: 27),
    KeyGeometry(row: 3, col: 4, x: 4.25, y: 3.0, w: 1.0, h: 1.0, index: 49, name: 'C', defaultCode: 6),
    KeyGeometry(row: 3, col: 5, x: 5.25, y: 3.0, w: 1.0, h: 1.0, index: 50, name: 'V', defaultCode: 25),
    KeyGeometry(row: 3, col: 6, x: 6.25, y: 3.0, w: 1.0, h: 1.0, index: 51, name: 'B', defaultCode: 5),
    KeyGeometry(row: 3, col: 7, x: 7.25, y: 3.0, w: 1.0, h: 1.0, index: 52, name: 'N', defaultCode: 17),
    KeyGeometry(row: 3, col: 8, x: 8.25, y: 3.0, w: 1.0, h: 1.0, index: 53, name: 'M', defaultCode: 16),
    KeyGeometry(row: 3, col: 9, x: 9.25, y: 3.0, w: 1.0, h: 1.0, index: 54, name: '<', defaultCode: 54),
    KeyGeometry(row: 3, col: 10, x: 10.25, y: 3.0, w: 1.0, h: 1.0, index: 55, name: '>', defaultCode: 55),
    KeyGeometry(row: 3, col: 11, x: 11.25, y: 3.0, w: 1.0, h: 1.0, index: 56, name: '?', defaultCode: 56),
    KeyGeometry(row: 3, col: 13, x: 12.25, y: 3.0, w: 2.75, h: 1.0, index: 58, name: 'Shift', defaultCode: 229),

    // Row 4
    KeyGeometry(row: 4, col: 0, x: 0.0, y: 4.0, w: 1.25, h: 1.0, index: 60, name: 'Ctrl', defaultCode: 256),
    KeyGeometry(row: 4, col: 1, x: 1.25, y: 4.0, w: 1.25, h: 1.0, index: 61, name: 'Win', defaultCode: 2048),
    KeyGeometry(row: 4, col: 2, x: 2.5, y: 4.0, w: 1.25, h: 1.0, index: 62, name: 'Alt', defaultCode: 1024),
    KeyGeometry(row: 4, col: 6, x: 3.75, y: 4.0, w: 6.25, h: 1.0, index: 66, name: 'Space', defaultCode: 44),
    KeyGeometry(row: 4, col: 10, x: 10.0, y: 4.0, w: 1.5, h: 1.0, index: 70, name: 'Alt', defaultCode: 230),
    KeyGeometry(row: 4, col: 11, x: 11.5, y: 4.0, w: 1.0, h: 1.0, index: 71, name: 'Fn', defaultCode: 255),
    KeyGeometry(row: 4, col: 12, x: 12.5, y: 4.0, w: 1.5, h: 1.0, index: 72, name: 'App', defaultCode: 101),
    KeyGeometry(row: 4, col: 13, x: 14.0, y: 4.0, w: 1.0, h: 1.0, index: 73, name: 'RCtrl', defaultCode: 117),
  ];

  /// Loads layout asynchronously from bundle assets with fallback.
  static Future<List<KeyGeometry>> loadFromAsset({
    String path = 'assets/data/36ae_fe12.json',
  }) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      return parseLayout(jsonStr);
    } catch (_) {
      return fallbackLayout61;
    }
  }

  /// Alias for backward compatibility.
  static List<KeyGeometry> get layout61 => fallbackLayout61;
}
