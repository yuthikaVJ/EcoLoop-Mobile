import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

void main() {
  runApp(const EcoLoopApp());
}

class EcoLoopApp extends StatelessWidget {
  const EcoLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoLoop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
