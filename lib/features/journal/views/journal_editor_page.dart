import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_tokens.dart';
import '../bloc/journal_bloc.dart';
import '../models/journal_entry.dart';

class JournalEditorPage extends StatefulWidget {
  const JournalEditorPage({super.key, this.entry});

  final JournalEntry? entry;

  @override
  State<JournalEditorPage> createState() => _JournalEditorPageState();
}

class _JournalEditorPageState extends State<JournalEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  bool _allowPop = false;
  bool _confirming = false;
  bool _pendingOperation = false;

  bool get _dirty =>
      _title.text != (widget.entry?.title ?? '') ||
      _body.text != (widget.entry?.body ?? '');

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title ?? '');
    _body = TextEditingController(text: widget.entry?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _close() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _requestLeave() async {
    if (_confirming || _pendingOperation) return;
    if (!_dirty) {
      _close();
      return;
    }
    _confirming = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved writing will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep writing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _confirming = false;
    if (mounted && discard == true) _close();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _pendingOperation = true);
    context.read<JournalBloc>().add(JournalDeleteRequested(widget.entry!.id));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _pendingOperation = true);
    context.read<JournalBloc>().add(
      JournalSaveRequested(
        id: widget.entry?.id,
        title: _title.text,
        body: _body.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalBloc, JournalState>(
      listener: (context, state) {
        if (!_pendingOperation) return;
        if (state.status == JournalStatus.saved ||
            state.status == JournalStatus.deleted) {
          _close();
        } else if (state.status == JournalStatus.failure) {
          setState(() => _pendingOperation = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final busy = state.isBusy || _pendingOperation;
        return PopScope(
          canPop: _allowPop || (!_dirty && !busy),
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !busy) _requestLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Back to journal',
                onPressed: busy ? null : _requestLeave,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(widget.entry == null ? 'New entry' : 'Edit entry'),
              actions: [
                if (widget.entry != null)
                  IconButton(
                    tooltip: 'Delete entry',
                    onPressed: busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                IconButton(
                  tooltip: 'Save entry',
                  onPressed: busy ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Form(
                    key: _formKey,
                    onChanged: () => setState(() {}),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      children: [
                        Text(
                          'Temporary entry. Not encrypted.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.large),
                        if (busy) const LinearProgressIndicator(),
                        TextFormField(
                          controller: _title,
                          enabled: !busy,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Title (optional)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        TextFormField(
                          controller: _body,
                          enabled: !busy,
                          minLines: 10,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Your thoughts',
                            alignLabelWithHint: true,
                            border: InputBorder.none,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Write something before saving.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
