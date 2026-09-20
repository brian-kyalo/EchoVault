import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_identity.dart';
import '../../../app/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../bloc/journal_bloc.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppIdentity.name),
        actions: [
          IconButton(
            tooltip: 'About EchoVault',
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.about),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: BlocBuilder<JournalBloc, JournalState>(
              builder: (context, state) {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Journal',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.small),
                            Text(
                              'SESSION PREVIEW',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.small),
                            const Text(
                              'Entries disappear when the app restarts. '
                              'Encryption is not active. Use sample writing only.',
                            ),
                            const SizedBox(height: AppSpacing.large),
                            Text(
                              '${state.entries.length} ${state.entries.length == 1 ? 'entry' : 'entries'}',
                              style: theme.textTheme.labelLarge,
                            ),
                            if (state.isBusy) ...[
                              const SizedBox(height: AppSpacing.medium),
                              const LinearProgressIndicator(),
                            ],
                            if (state.status == JournalStatus.failure) ...[
                              const SizedBox(height: AppSpacing.medium),
                              Text(
                                state.message!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => context
                                    .read<JournalBloc>()
                                    .add(const JournalLoadRequested()),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry loading'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (state.entries.isEmpty &&
                        !state.isBusy &&
                        state.status != JournalStatus.failure)
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                size: 64,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: AppSpacing.medium),
                              Text(
                                'A fresh page',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.small),
                              const Text(
                                'What is on your mind today?',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverList.builder(
                      itemCount: state.entries.length,
                      itemBuilder: (context, index) {
                        final entry = state.entries[index];
                        final date = MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(entry.updatedAt);
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.large,
                                vertical: AppSpacing.small,
                              ),
                              title: Text(
                                entry.title.isEmpty
                                    ? 'Untitled entry'
                                    : entry.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    entry.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    date,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: state.isBusy
                                  ? null
                                  : () => Navigator.of(context).pushNamed(
                                      AppRouter.editor,
                                      arguments: entry,
                                    ),
                            ),
                            const Divider(
                              height: 1,
                              indent: AppSpacing.large,
                              endIndent: AppSpacing.large,
                            ),
                          ],
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<JournalBloc, JournalState>(
        builder: (context, state) => FloatingActionButton.extended(
          onPressed: state.isBusy
              ? null
              : () => Navigator.of(context).pushNamed(AppRouter.editor),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New entry'),
        ),
      ),
    );
  }
}
