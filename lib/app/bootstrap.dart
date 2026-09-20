import 'package:flutter/widgets.dart';

import 'app.dart';

/// The composition entry point for future repositories and BLoC providers.
void bootstrap() {
  // No asynchronous resources exist yet. Storage initialization belongs here
  // later, rather than inside a widget's build method.
  runApp(const EchoVaultApp());
}
