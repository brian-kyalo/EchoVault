import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

class BuildInfoDialog extends StatelessWidget {
  const BuildInfoDialog({super.key});

  static Future<void> show(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return showDialog<void>(
      context: context,
      animationStyle: AnimationStyle(
        duration: reduceMotion ? Duration.zero : AppDurations.dialogTransition,
        reverseDuration: reduceMotion
            ? Duration.zero
            : AppDurations.dialogTransition,
      ),
      builder: (context) => const BuildInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What is ready?'),
      scrollable: true,
      content: const Text(
        'This build supports creating, editing, and deleting journal entries '
        'through BLoC. Entries stay in memory only and disappear when the app restarts.\n\n'
        'Encrypted local storage, app lock, spelling games, '
        'and offline speech are planned, not implemented.\n\n'
        'No account, analytics service, or remote AI service is connected. '
        'Do not use this preview to store private writing.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to welcome'),
        ),
      ],
    );
  }
}
