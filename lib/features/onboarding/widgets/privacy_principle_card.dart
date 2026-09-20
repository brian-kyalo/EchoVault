import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

class PrivacyPrincipleCard extends StatelessWidget {
  const PrivacyPrincipleCard({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The text conveys the meaning; the icon is purely decorative.
            ExcludeSemantics(
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
