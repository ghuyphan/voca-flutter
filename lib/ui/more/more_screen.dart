// lib/ui/more/more_screen.dart

import 'package:flutter/material.dart';
import '../settings/settings_screen.dart';

export '../settings/settings_screen.dart';

/// MoreScreen now unifies directly with [SettingsScreen].
/// This wrapper ensures full backwards-compatibility with existing tests and imports.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}
