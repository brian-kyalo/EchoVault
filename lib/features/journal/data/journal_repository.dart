import '../models/journal_entry.dart';

abstract interface class JournalRepository {
  Future<List<JournalEntry>> load();

  Future<void> save({String? id, required String title, required String body});

  Future<void> delete(String id);
}

class InMemoryJournalRepository implements JournalRepository {
  final Map<String, JournalEntry> _entries = {};
  int _nextId = 0;

  @override
  Future<List<JournalEntry>> load() async {
    final entries = _entries.values.toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return List.unmodifiable(entries);
  }

  @override
  Future<void> save({
    String? id,
    required String title,
    required String body,
  }) async {
    final existing = id == null ? null : _entries[id];
    if (id != null && existing == null) {
      throw StateError('Entry no longer exists.');
    }
    final now = DateTime.now();
    final entryId = id ?? '${++_nextId}';
    _entries[entryId] = JournalEntry(
      id: entryId,
      title: title,
      body: body,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  @override
  Future<void> delete(String id) async {
    _entries.remove(id);
  }
}
