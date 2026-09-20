import 'package:flutter/material.dart';

import '../../../app/app_identity.dart';
import '../../../core/theme/app_tokens.dart';
import '../widgets/build_info_dialog.dart';
import '../widgets/privacy_principle_card.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About EchoVault')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            // No fixed content height: small screens and large text can scroll.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppIdentity.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'PERSONAL JOURNAL / LOCAL FIRST',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Semantics(
                    header: true,
                    child: Text(
                      'My thoughts\nbelong to me.',
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(AppIdentity.tagline, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.extraLarge),
                  Text(
                    'OUR DESIGN PRINCIPLES',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const PrivacyPrincipleCard(
                    icon: Icons.lock_outline_rounded,
                    title: 'Private by design',
                    description:
                        'The journal will encrypt your writing before saving '
                        'it locally. No account or cloud database is planned '
                        'for version one.',
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  const PrivacyPrincipleCard(
                    icon: Icons.spellcheck_rounded,
                    title: 'Learn words, not your story',
                    description:
                        'Spelling practice will use only corrections you accept. '
                        'Learning records will never include journal sentences, '
                        'titles, or entry identifiers.',
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  Text(
                    'SESSION PREVIEW',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Journal entries stay in memory only and disappear when '
                    'the app restarts. Encryption is not active. '
                    'Use sample writing only.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  FilledButton(
                    onPressed: () => BuildInfoDialog.show(context),
                    child: const Text('About this build'),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
