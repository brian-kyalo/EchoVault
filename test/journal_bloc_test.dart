import 'dart:async';

import 'package:echo_vault/features/journal/bloc/journal_bloc.dart';
import 'package:echo_vault/features/journal/data/journal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<JournalState> dispatch(
  JournalBloc bloc,
  JournalEvent event,
  JournalStatus status,
) {
  final result = bloc.stream.firstWhere((state) => state.status == status);
  bloc.add(event);
  return result;
}

void main() {
  test('loads, creates, edits and deletes immutable session entries', () async {
    final repository = InMemoryJournalRepository();
    final bloc = JournalBloc(repository);
    addTearDown(bloc.close);

    final loaded = await dispatch(
      bloc,
      const JournalLoadRequested(),
      JournalStatus.ready,
    );
    expect(loaded.entries, isEmpty);

    final saved = await dispatch(
      bloc,
      const JournalSaveRequested(title: ' Today ', body: ' First thought '),
      JournalStatus.saved,
    );
    final entry = saved.entries.single;
    expect(entry.title, 'Today');
    expect(entry.body, 'First thought');
    expect(() => saved.entries.clear(), throwsUnsupportedError);

    final edited = await dispatch(
      bloc,
      JournalSaveRequested(
        id: entry.id,
        title: 'Changed',
        body: 'Second thought',
      ),
      JournalStatus.saved,
    );
    expect(edited.entries.single.id, entry.id);
    expect(edited.entries.single.createdAt, entry.createdAt);
    expect(edited.entries.single.body, 'Second thought');
    expect(saved.entries.single.body, 'First thought');

    final deleted = await dispatch(
      bloc,
      JournalDeleteRequested(entry.id),
      JournalStatus.deleted,
    );
    expect(deleted.entries, isEmpty);
    expect(await InMemoryJournalRepository().load(), isEmpty);
  });

  test('rejects blank writing without saving', () async {
    final repository = InMemoryJournalRepository();
    final bloc = JournalBloc(repository);
    addTearDown(bloc.close);
    final result = await dispatch(
      bloc,
      const JournalSaveRequested(title: 'Title', body: ' \n '),
      JournalStatus.failure,
    );
    expect(result.message, 'Write something before saving.');
    expect(await repository.load(), isEmpty);
  });

  test('keeps existing entries on failure and permits retry', () async {
    final repository = FailingJournalRepository();
    final bloc = JournalBloc(repository);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      const JournalSaveRequested(title: 'One', body: 'Body'),
      JournalStatus.saved,
    );
    repository.failSave = true;
    final failed = await dispatch(
      bloc,
      const JournalSaveRequested(title: 'Two', body: 'Draft'),
      JournalStatus.failure,
    );
    expect(failed.entries.single.title, 'One');
    expect(failed.message, 'Could not save your entry. Try again.');
    repository.failSave = false;
    final retried = await dispatch(
      bloc,
      const JournalSaveRequested(title: 'Two', body: 'Draft'),
      JournalStatus.saved,
    );
    expect(retried.entries, hasLength(2));
  });

  test(
    'serializes saves so later operations cannot overtake earlier ones',
    () async {
      final repository = DelayedJournalRepository();
      final bloc = JournalBloc(repository);
      addTearDown(bloc.close);
      final savedStates = bloc.stream
          .where((state) => state.status == JournalStatus.saved)
          .take(2)
          .toList();
      bloc.add(const JournalSaveRequested(title: 'First', body: 'First body'));
      await repository.started.future;
      bloc.add(
        const JournalSaveRequested(title: 'Second', body: 'Second body'),
      );
      repository.release.complete();
      final results = await savedStates;
      expect(results.first.entries.single.title, 'First');
      expect(results.last.entries, hasLength(2));
    },
  );

  test('does not recreate a deleted entry on edit', () async {
    final bloc = JournalBloc(InMemoryJournalRepository());
    addTearDown(bloc.close);
    final result = await dispatch(
      bloc,
      const JournalSaveRequested(id: 'missing', title: '', body: 'Draft'),
      JournalStatus.failure,
    );
    expect(result.entries, isEmpty);
  });
}

class FailingJournalRepository extends InMemoryJournalRepository {
  bool failSave = false;

  @override
  Future<void> save({String? id, required String title, required String body}) {
    if (failSave) throw StateError('Private implementation detail');
    return super.save(id: id, title: title, body: body);
  }
}

class DelayedJournalRepository extends InMemoryJournalRepository {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> save({
    String? id,
    required String title,
    required String body,
  }) async {
    if (!started.isCompleted) {
      started.complete();
      await release.future;
    }
    await super.save(id: id, title: title, body: body);
  }
}
