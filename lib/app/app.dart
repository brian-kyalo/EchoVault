import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../features/journal/bloc/journal_bloc.dart';
import '../features/journal/data/journal_repository.dart';
import 'app_identity.dart';
import 'app_router.dart';

class EchoVaultApp extends StatelessWidget {
  const EchoVaultApp({super.key, this.journalRepository});

  final JournalRepository? journalRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<JournalRepository>(
      create: (_) => journalRepository ?? InMemoryJournalRepository(),
      child: BlocProvider(
        create: (context) =>
            JournalBloc(context.read<JournalRepository>())
              ..add(const JournalLoadRequested()),
        child: MaterialApp(
          title: AppIdentity.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
