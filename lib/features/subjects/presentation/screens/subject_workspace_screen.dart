import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/domain/entities/note.dart';
import '../../../notes/presentation/controllers/notes_controller.dart';

class SubjectWorkspaceScreen extends ConsumerStatefulWidget {
  final int subjectId;
  final String subjectName;

  const SubjectWorkspaceScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  ConsumerState<SubjectWorkspaceScreen> createState() =>
      _SubjectWorkspaceScreenState();
}

class _SubjectWorkspaceScreenState
    extends ConsumerState<SubjectWorkspaceScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final notesController = ref.watch(
      notesControllerProvider(widget.subjectId),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Subject workspace',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Search will come later.
            },
            icon: const Icon(
              Icons.search_rounded,
            ),
          ),
          IconButton(
            onPressed: () {
              // Subject options will come later.
            },
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: notesController.watchNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    error: snapshot.error,
                  );
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return _EmptyWorkspace(
                    subjectName: widget.subjectName,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    20,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];

                    return _NoteBubble(
                      note: note,
                      onDelete: () {
                        _deleteNote(
                          notesController,
                          note.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          _Composer(
            controller: _messageController,
            sending: _sending,
            onSend: () {
              _sendTextNote(notesController);
            },
            onAttachment: () {
              // Attachment picker will be connected next.
            },
            onCamera: () {
              // Camera will be connected later.
            },
            onVoice: () {
              // Voice recorder will be connected later.
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextNote(
    NotesController controller,
  ) async {
    final content = _messageController.text.trim();

    if (content.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await controller.createTextNote(content);

      _messageController.clear();

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save note: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _deleteNote(
    NotesController controller,
    int noteId,
  ) async {
    try {
      await controller.deleteNote(noteId);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete note: $error',
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────
// NOTE BUBBLE
// ─────────────────────────────────────────

class _NoteBubble extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const _NoteBubble({
    required this.note,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final time = _formatTime(note.createdAt);

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
        ),
        child: GestureDetector(
          onLongPress: () {
            _showActions(context);
          },
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.sizeOf(context).width *
                      0.82,
            ),
            padding: const EdgeInsets.fromLTRB(
              15,
              11,
              12,
              8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme
                  .primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(5),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    note.content,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  time,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(
                    color: theme.colorScheme
                        .onPrimaryContainer
                        .withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                ),
                title: const Text(
                  'Delete note',
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}

// ─────────────────────────────────────────
// COMPOSER
// ─────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;

  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback onCamera;
  final VoidCallback onVoice;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onAttachment,
    required this.onCamera,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          10,
          8,
          10,
          8,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.25),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: sending
                  ? null
                  : onAttachment,
              icon: const Icon(
                Icons.attach_file_rounded,
              ),
            ),

            Expanded(
              child: Container(
                constraints:
                    const BoxConstraints(
                  minHeight: 46,
                  maxHeight: 130,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Write a note...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!sending) {
                      onSend();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 4),

            if (controller.text.trim().isEmpty)
              IconButton(
                onPressed: sending
                    ? null
                    : onCamera,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                ),
              ),

            if (controller.text.trim().isEmpty)
              IconButton(
                onPressed: sending
                    ? null
                    : onVoice,
                icon: const Icon(
                  Icons.mic_none_rounded,
                ),
              ),

            if (controller.text.trim().isNotEmpty)
              IconButton(
                onPressed: sending
                    ? null
                    : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────

class _EmptyWorkspace extends StatelessWidget {
  final String subjectName;

  const _EmptyWorkspace({
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: theme.colorScheme
                    .surfaceContainerHighest,
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 35,
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              subjectName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Start capturing what you learn.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                color: theme.colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ERROR
// ─────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final Object? error;

  const _ErrorState({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load notes.',
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}