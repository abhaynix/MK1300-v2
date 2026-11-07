import 'macro_action.dart';

/// Represents one of the 16 hardware macro slots.
class MacroModel {
  String name;
  List<MacroAction> actions;
  int loopMode; // 0 = Execute once, 1 = Loop until release, 2 = Until any, 3 = Toggle, 4 = Repeat N

  MacroModel({
    required this.name,
    required this.actions,
    this.loopMode = 0,
  });

  factory MacroModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['list'] as List<dynamic>? ?? [];
    return MacroModel(
      name: json['name'] as String? ?? 'Macro',
      actions: rawList.map((item) => MacroAction.fromJson(item as Map<String, dynamic>)).toList(),
      loopMode: json['loopMode'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'list': actions.map((a) => a.toJson()).toList(),
    'loopMode': loopMode,
  };
}
