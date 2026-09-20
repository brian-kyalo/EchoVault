import 'package:flutter/material.dart';

import '../features/journal/models/journal_entry.dart';
import '../features/journal/views/journal_editor_page.dart';
import '../features/journal/views/journal_page.dart';
import '../features/onboarding/views/welcome_page.dart';

abstract final class AppRouter {
  static const journal = '/';
  static const editor = '/entry';
  static const about = '/about';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      journal => const JournalPage(),
      editor => JournalEditorPage(entry: settings.arguments as JournalEntry?),
      about => const WelcomePage(),
      _ => const JournalPage(),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
