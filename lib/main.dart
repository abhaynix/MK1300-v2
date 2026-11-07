import 'package:flutter/material.dart';
import 'app/theme/theme.dart';
import 'hardware/services/keyboard_service.dart';
import 'shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize central keyboard hardware controller
  final keyboardService = KeyboardService();
  await keyboardService.connect();

  runApp(Mk1300App(keyboardService: keyboardService));
}

class Mk1300App extends StatelessWidget {
  final KeyboardService keyboardService;

  const Mk1300App({super.key, required this.keyboardService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ant Esports MK1300 V2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AppShell(keyboardService: keyboardService),
    );
  }
}
