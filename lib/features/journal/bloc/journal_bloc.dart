import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/journal_repository.dart';
import '../models/journal_entry.dart';

sealed class JournalEvent {
  const JournalEvent();
}

final class JournalLoadRequested extends JournalEvent {
  const JournalLoadRequested();
}

final class JournalSaveRequested extends JournalEvent {
  const JournalSaveRequested({
    this.id,
    required this.title,
    required this.body,
  });

  final String? id;
  final String title;
  final String body;
}

final class JournalDeleteRequested extends JournalEvent {
  const JournalDeleteRequested(this.id);

  final String id;
}

enum JournalStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  deleting,
  deleted,
  failure,
}

class JournalState {
  JournalState({
    this.status = JournalStatus.initial,
    List<JournalEntry> entries = const [],
    this.message,
  }) : entries = List.unmodifiable(entries);

  final JournalStatus status;
  final List<JournalEntry> entries;
  final String? message;

  bool get isBusy =>
      status == JournalStatus.loading ||
      status == JournalStatus.saving ||
      status == JournalStatus.deleting;
}

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc(this._repository) : super(JournalState()) {
    on<JournalEvent>(_handleEvent, transformer: sequential());
  }

  final JournalRepository _repository;

  Future<void> _handleEvent(
    JournalEvent event,
    Emitter<JournalState> emit,
  ) async {
    if (event is JournalSaveRequested && event.body.trim().isEmpty) {
      emit(
        JournalState(
          status: JournalStatus.failure,
          entries: state.entries,
          message: 'Write something before saving.',
        ),
      );
      return;
    }

    final busyStatus = switch (event) {
      JournalLoadRequested() => JournalStatus.loading,
      JournalSaveRequested() => JournalStatus.saving,
      JournalDeleteRequested() => JournalStatus.deleting,
    };
    emit(JournalState(status: busyStatus, entries: state.entries));

    try {
      switch (event) {
        case JournalLoadRequested():
          break;
        case JournalSaveRequested(:final id, :final title, :final body):
          await _repository.save(
            id: id,
            title: title.trim(),
            body: body.trim(),
          );
        case JournalDeleteRequested(:final id):
          await _repository.delete(id);
      }
      final entries = await _repository.load();
      final status = switch (event) {
        JournalLoadRequested() => JournalStatus.ready,
        JournalSaveRequested() => JournalStatus.saved,
        JournalDeleteRequested() => JournalStatus.deleted,
      };
      emit(JournalState(status: status, entries: entries));
    } catch (_) {
      emit(
        JournalState(
          status: JournalStatus.failure,
          entries: state.entries,
          message: switch (event) {
            JournalLoadRequested() => 'Could not load your entries. Try again.',
            JournalSaveRequested() => 'Could not save your entry. Try again.',
            JournalDeleteRequested() =>
              'Could not delete your entry. Try again.',
          },
        ),
      );
    }
  }
}
