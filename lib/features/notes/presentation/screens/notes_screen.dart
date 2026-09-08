import 'dart:async';
import 'dart:io';

import 'package:alfred/features/attachments/presentation/controllers/attachment_controller.dart';
import 'package:alfred/features/attachments/presentation/controllers/audio_providers.dart';
import 'package:alfred/features/attachments/presentation/widget/attachment_menu.dart';
import 'package:alfred/features/notes/presentation/widgets/audio_message_bubble.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../attachments/domain/entities/attachment.dart';
import '../../domain/entities/note.dart';
import '../controllers/notes_controller.dart';
import '../widgets/note_bubble.dart';
import '../widgets/note_empty_state.dart';
// i wnat some new features in thi s code i want user able to copy note

// and user able to share note content with other apps.multiple content to app share
// i want edit note feature
// i want whstapp liek text stling buller number list bold italic basically
// in whstapp doing this is tough use rgenrlayy donot know how to style i wnat simplme feature to do so

class NotesScreen extends ConsumerStatefulWidget {
  final int subjectId;
  final String subjectName;

  const NotesScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSending = false;
  Note? _editingNote;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  void _startEdit(Note note) {
    setState(() {
      _editingNote = note;
      _textController.text = note.content;
      _textController.selection = TextSelection.collapsed(
        offset: note.content.length,
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingNote = null;
      _textController.clear();
    });
  }

  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _pendingAttachments = [];
  Future<void> _summarizeNote(Note note) async {
    final controller = ref.read(notesControllerProvider(widget.subjectId));

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('Summarizing…'),
          ],
        ),
      ),
    );

    try {
      final summary = await controller.summarizeNote(note.content);

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Summary'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: summary));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Summarize failed: $e')));
    }
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('No notes found', style: AppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text(
              'Try a different search term.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final controller = ref.read(notesControllerProvider(widget.subjectId));

    final notes = await controller.watchNotes().first;

    if (!mounted) return;

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no notes to delete.')),
      );

      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete all notes?'),
          content: Text(
            'This will permanently delete '
            '${notes.length} ${notes.length == 1 ? 'note' : 'notes'} '
            'and all their attachments.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await controller.deleteAllNotes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${notes.length} '
            '${notes.length == 1 ? 'note' : 'notes'} deleted.',
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('DELETE ALL NOTES ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete notes: $e')));
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AttachmentMenu(
          onCamera: () {
            Navigator.pop(context);
            _pickCamera();
          },
          onGallery: () {
            Navigator.pop(context);
            _pickGallery();
          },
          onFile: () {
            Navigator.pop(context);
            _pickFile();
          },
        );
      },
    );
  }

  Future<void> _pickCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _pendingAttachments.add(File(image.path));
    });
  }

  Future<void> _pickGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _pendingAttachments.add(File(image.path));
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);

    final files = result
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();

    if (files.isEmpty) {
      return;
    }

    setState(() {
      _pendingAttachments.addAll(files);
    });
  }

  Future<void> _startRecording() async {
    if (_isSending || _isRecording) {
      return;
    }

    try {
      final recorder = ref.read(audioRecorderProvider);
      final allowed = await recorder.hasPermission();

      if (!allowed) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );

        return;
      }

      await recorder.start();

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer?.cancel();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) {
          return;
        }

        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
      });
    } catch (e, stackTrace) {
      debugPrint('START RECORDING ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to start recording: $e')));
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) {
      debugPrint('STOP: Not currently recording');
      return;
    }

    try {
      debugPrint('STOP: Stopping recorder...');

      _recordingTimer?.cancel();
      _recordingTimer = null;

      final recorder = ref.read(audioRecorderProvider);

      final path = await recorder.stop();

      debugPrint('STOP: Recorder returned path = $path');

      if (!mounted) {
        debugPrint('STOP: Widget is no longer mounted');
        return;
      }

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      if (path == null || path.trim().isEmpty) {
        debugPrint('STOP ERROR: Recorder returned NULL/EMPTY path');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording stopped, but no audio file was created.'),
          ),
        );

        return;
      }

      final file = File(path);

      debugPrint('STOP: File path = ${file.path}');
      debugPrint('STOP: File exists = ${await file.exists()}');

      if (!await file.exists()) {
        debugPrint('STOP ERROR: Audio file does not exist');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio file was not found:\n$path')),
        );

        return;
      }

      final fileSize = await file.length();

      debugPrint('STOP: Audio file size = $fileSize bytes');

      if (fileSize == 0) {
        debugPrint('STOP ERROR: Audio file is EMPTY');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file is empty.')),
        );

        return;
      }

      setState(() {
        _pendingAttachments.add(file);
      });

      debugPrint(
        'STOP SUCCESS: Added audio to pending attachments. '
        'Count = ${_pendingAttachments.length}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice recording ready (${(fileSize / 1024).toStringAsFixed(1)} KB)',
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('STOP RECORDING ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to stop recording: $e')));
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final recorder = ref.read(audioRecorderProvider);

    await recorder.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _textController.addListener(_onTextChanged);

    _searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _retrieveLostImage();
  }

  Future<void> _retrieveLostImage() async {
    try {
      final LostDataResponse response = await _imagePicker.retrieveLostData();

      if (response.isEmpty) {
        return;
      }

      if (response.files != null && response.files!.isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _pendingAttachments.addAll(
            response.files!.map((xFile) => File(xFile.path)),
          );
        });

        debugPrint('LOST IMAGE RECOVERED: ${response.files!.length} file(s)');
      }

      if (response.exception != null) {
        debugPrint('LOST IMAGE ERROR: ${response.exception}');
      }
    } catch (e, stackTrace) {
      debugPrint('RETRIEVE LOST IMAGE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);

    _textController.dispose();
    _searchController.dispose();
    _focusNode.dispose();

    _recordingTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(notesControllerProvider(widget.subjectId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.subjectName, style: AppTextStyles.headingSmall),
                  const Text('Notes', style: AppTextStyles.bodySmall),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;

                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete_all') {
                await _confirmDeleteAll();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete all notes'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: controller.watchNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load notes',
                      style: AppTextStyles.bodyMedium,
                    ),
                  );
                }

                final notes = snapshot.data ?? [];

                if (notes.isEmpty) {
                  return const NoteEmptyState();
                }

                return _buildNotesList(notes);
              },
            ),
          ),

          _buildComposer(controller),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    final filteredNotes = _searchQuery.isEmpty
        ? notes
        : notes.where((note) {
            return note.content.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();

    if (filteredNotes.isEmpty) {
      return _buildNoSearchResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space20,
        AppDimensions.space16,
        AppDimensions.space20,
      ),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];

        final attachmentController = ref.watch(
          attachmentControllerProvider(note.id),
        );

        return StreamBuilder<List<Attachment>>(
          stream: attachmentController.watchAttachments(),
          builder: (context, snapshot) {
            final attachments = snapshot.data ?? [];
            return NoteBubble(
              note: note,
              attachments: attachments.map(_buildAttachmentWidget).toList(),
              attachmentPaths: attachments.map((a) => a.path).toList(),
              onDelete: () => _confirmDelete(note),
              onEdit: () => _startEdit(note),
              onSummarize: note.content.trim().isEmpty
                  ? null
                  : () => _summarizeNote(note),
            );
          },
        );
      },
    );
  }

  Widget _buildAttachmentWidget(Attachment attachment) {
    if (attachment.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(attachment.path),
          width: 220,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 220,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined),
                  SizedBox(width: 8),
                  Text('Image unavailable'),
                ],
              ),
            );
          },
        ),
      );
    }

    if (attachment.type == 'audio') {
      return AudioMessageBubble(path: attachment.path);
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_rounded),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(NotesController controller) {
    if (_isRecording) {
      return _buildRecordingComposer();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space8,
          AppDimensions.space8,
          AppDimensions.space8,
          AppDimensions.space8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editingNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Editing note',
                        style: AppTextStyles.labelSmall,
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelEdit,
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),

            _buildFormattingToolbar(),

            if (_pendingAttachments.isNotEmpty) _buildPendingAttachments(),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _showAttachmentMenu,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),

                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,

                    minLines: 1,
                    maxLines: 8,

                    inputFormatters: [NoteListInputFormatter()],

                    textCapitalization: TextCapitalization.sentences,

                    decoration: InputDecoration(
                      hintText: _editingNote != null
                          ? 'Edit note...'
                          : 'Write a note...',
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppDimensions.space4),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      _textController.text.trim().isNotEmpty ||
                          _pendingAttachments.isNotEmpty
                      ? IconButton(
                          key: const ValueKey('send'),
                          onPressed: _isSending
                              ? null
                              : () => _sendNote(controller),
                          icon: _isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _editingNote != null
                                      ? Icons.check_rounded
                                      : Icons.arrow_upward_rounded,
                                ),
                        )
                      : IconButton(
                          key: const ValueKey('voice'),
                          onPressed: _editingNote != null
                              ? null
                              : _startRecording,
                          icon: const Icon(Icons.mic_none_rounded),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _cancelRecording,
              icon: const Icon(Icons.delete_outline_rounded),
            ),

            const SizedBox(width: 8),

            const Icon(Icons.fiber_manual_record, size: 12, color: Colors.red),

            const SizedBox(width: 8),

            Text(
              _formatDuration(_recordingDuration),
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(width: 16),

            const Expanded(
              child: Text(
                'Recording voice note...',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium,
              ),
            ),

            IconButton(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop_circle_outlined, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  Widget _buildPendingAttachments() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: _pendingAttachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final file = _pendingAttachments[index];

          final extension = file.path.toLowerCase();

          final isAudio =
              extension.endsWith('.m4a') ||
              extension.endsWith('.mp3') ||
              extension.endsWith('.wav') ||
              extension.endsWith('.aac') ||
              extension.endsWith('.ogg') ||
              extension.endsWith('.opus') ||
              extension.endsWith('.webm') ||
              extension.endsWith('.mp4');
          return Stack(
            children: [
              Container(
                width: isAudio ? 140 : 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isAudio
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_rounded),
                          SizedBox(width: 6),
                          Text('Voice'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),

              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _pendingAttachments.removeAt(index);
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendNote(NotesController controller) async {
    final text = _textController.text.trim();

    if (_isSending) return;

    final isEditing = _editingNote != null;

    if (text.isEmpty && !isEditing && _pendingAttachments.isEmpty) return;
    if (isEditing && text.isEmpty)
      return; // don't allow saving an edit into empty content

    setState(() => _isSending = true);

    try {
      if (isEditing) {
        await controller.updateNote(_editingNote!, text);
      } else {
        await controller.createNoteWithAttachments(
          content: text,
          files: List<File>.from(_pendingAttachments),
        );
      }

      if (!mounted) return;

      setState(() {
        _textController.clear();
        _pendingAttachments.clear();
        _editingNote = null;
      });

      _focusNode.requestFocus();
    } catch (e, stackTrace) {
      debugPrint('SEND NOTE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _applyInlineFormat(String marker) {
    final value = _textController.value;
    final text = value.text;

    if (!value.selection.isValid) {
      return;
    }

    int start = value.selection.start;
    int end = value.selection.end;

    start = start.clamp(0, text.length);
    end = end.clamp(0, text.length);

    // ==================================================
    // NO SELECTION
    // ==================================================

    if (start == end) {
      // Find the current word.
      int wordStart = start;
      int wordEnd = start;

      while (wordStart > 0 && !_isFormattingSeparator(text[wordStart - 1])) {
        wordStart--;
      }

      while (wordEnd < text.length && !_isFormattingSeparator(text[wordEnd])) {
        wordEnd++;
      }

      // If cursor is inside a word, format the whole word.
      if (wordStart != wordEnd && start > wordStart && start < wordEnd) {
        final word = text.substring(wordStart, wordEnd);

        final alreadyFormatted =
            word.startsWith(marker) &&
            word.endsWith(marker) &&
            word.length > marker.length * 2;

        if (alreadyFormatted) {
          final cleanWord = word.substring(
            marker.length,
            word.length - marker.length,
          );

          final newText = text.replaceRange(wordStart, wordEnd, cleanWord);

          _textController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: wordStart + cleanWord.length,
            ),
          );
        } else {
          final formattedWord = '$marker$word$marker';

          final newText = text.replaceRange(wordStart, wordEnd, formattedWord);

          _textController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: wordStart + formattedWord.length,
            ),
          );
        }

        return;
      }

      // No word: insert formatting markers.
      final newText = text.replaceRange(start, end, '$marker$marker');

      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + marker.length),
      );

      return;
    }

    // ==================================================
    // TEXT IS SELECTED
    // ==================================================

    final selectedText = text.substring(start, end);

    final isAlreadyFormatted =
        selectedText.startsWith(marker) &&
        selectedText.endsWith(marker) &&
        selectedText.length > marker.length * 2;

    String replacement;

    if (isAlreadyFormatted) {
      replacement = selectedText.substring(
        marker.length,
        selectedText.length - marker.length,
      );
    } else {
      replacement = '$marker$selectedText$marker';
    }

    final newText = text.replaceRange(start, end, replacement);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  bool _isFormattingSeparator(String char) {
    return char == ' ' ||
        char == '\n' ||
        char == '\t' ||
        char == '.' ||
        char == ',' ||
        char == '!' ||
        char == '?' ||
        char == ':' ||
        char == ';' ||
        char == '(' ||
        char == ')' ||
        char == '[' ||
        char == ']' ||
        char == '{' ||
        char == '}' ||
        char == '"' ||
        char == "'";
  }

  void _applyLinePrefix(String type) {
    final value = _textController.value;
    final text = value.text;

    if (!value.selection.isValid) {
      return;
    }

    int selectionStart = value.selection.start;
    int selectionEnd = value.selection.end;

    selectionStart = selectionStart.clamp(0, text.length);
    selectionEnd = selectionEnd.clamp(0, text.length);

    // ==================================================
    // FIND FIRST LINE
    // ==================================================

    int blockStart = text.lastIndexOf(
      '\n',
      selectionStart > 0 ? selectionStart - 1 : 0,
    );

    blockStart = blockStart == -1 ? 0 : blockStart + 1;

    // ==================================================
    // FIND LAST LINE
    // ==================================================

    int blockEnd = text.indexOf('\n', selectionEnd);

    blockEnd = blockEnd == -1 ? text.length : blockEnd;

    final block = text.substring(blockStart, blockEnd);

    final lines = block.split('\n');

    // ==================================================
    // BULLET
    // ==================================================

    if (type == 'bullet') {
      final formattedLines = <String>[];

      for (final line in lines) {
        String content = line;

        // Remove existing numbered prefix.
        content = content.replaceFirst(RegExp(r'^\d+\.\s+'), '');

        // Toggle bullet.
        if (content.startsWith('• ')) {
          content = content.substring(2);
        } else {
          content = '• $content';
        }

        formattedLines.add(content);
      }

      final replacement = formattedLines.join('\n');

      final newText = text.replaceRange(blockStart, blockEnd, replacement);

      final newCursor = (blockStart + replacement.length).clamp(
        0,
        newText.length,
      );

      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );

      return;
    }

    // ==================================================
    // NUMBERED
    // ==================================================

    if (type == 'number') {
      final formattedLines = <String>[];

      bool allAlreadyNumbered = true;

      for (final line in lines) {
        if (!RegExp(r'^\d+\.\s+').hasMatch(line)) {
          allAlreadyNumbered = false;
          break;
        }
      }

      // If all selected lines are numbered,
      // clicking number again removes numbering.
      if (allAlreadyNumbered) {
        for (final line in lines) {
          formattedLines.add(line.replaceFirst(RegExp(r'^\d+\.\s+'), ''));
        }
      } else {
        int number = 1;

        for (final line in lines) {
          String content = line;

          // Remove bullet.
          content = content.replaceFirst(RegExp(r'^•\s+'), '');

          // Remove existing number.
          content = content.replaceFirst(RegExp(r'^\d+\.\s+'), '');

          formattedLines.add('$number. $content');

          number++;
        }
      }

      final replacement = formattedLines.join('\n');

      final newText = text.replaceRange(blockStart, blockEnd, replacement);

      final newCursor = (blockStart + replacement.length).clamp(
        0,
        newText.length,
      );

      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    }
  }
Widget _buildFormattingToolbar() {
  return SizedBox(
    height: 42,
    child: Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Bold',
          icon: const Icon(
            Icons.format_bold_rounded,
            size: 20,
          ),
          onPressed: () => _applyInlineFormat('*'),
        ),

        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Italic',
          icon: const Icon(
            Icons.format_italic_rounded,
            size: 20,
          ),
          onPressed: () => _applyInlineFormat('_'),
        ),

        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Strikethrough',
          icon: const Icon(
            Icons.strikethrough_s_rounded,
            size: 20,
          ),
          onPressed: () => _applyInlineFormat('~'),
        ),

        const SizedBox(width: 4),

        Container(
          width: 1,
          height: 22,
          color: AppColors.border,
        ),

        const SizedBox(width: 4),

        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Bullet list',
          icon: const Icon(
            Icons.format_list_bulleted_rounded,
            size: 20,
          ),
          onPressed: () => _applyLinePrefix('bullet'),
        ),

        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Numbered list',
          icon: const Icon(
            Icons.format_list_numbered_rounded,
            size: 20,
          ),
          onPressed: () => _applyLinePrefix('number'),
        ),
      ],
    ),
  );
}
  Future<void> _confirmDelete(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text('This note will be permanently removed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final controller = ref.read(notesControllerProvider(widget.subjectId));

    await controller.deleteNote(note.id);
  }
}

class NoteListInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Nothing changed.
    if (oldText == newText) {
      return newValue;
    }

    final cursor = newValue.selection.baseOffset;

    if (cursor < 1 ||
        cursor > newText.length) {
      return newValue;
    }

    // We only handle a single ENTER.
    //
    // This prevents pasted multiline text from
    // unexpectedly becoming a list.
    if (newText.length != oldText.length + 1) {
      return newValue;
    }

    // The newly inserted character must be newline.
    if (newText[cursor - 1] != '\n') {
      return newValue;
    }

    // Position of the newline.
    final newlineIndex = cursor - 1;

    // Find previous line start.
    final previousNewline = newText.lastIndexOf(
      '\n',
      newlineIndex - 1,
    );

    final previousLineStart =
        previousNewline == -1
            ? 0
            : previousNewline + 1;

    // Get line before the new newline.
    final previousLine = newText.substring(
      previousLineStart,
      newlineIndex,
    );

    // ==================================================
    // BULLET
    // ==================================================

    if (previousLine.startsWith('• ')) {
      final content = previousLine.substring(2);

      // Empty bullet:
      //
      // • hello
      // • |
      //
      // Enter ->
      //
      // • hello
      // |
      if (content.trim().isEmpty) {
        final updatedText = newText.replaceRange(
          previousLineStart,
          cursor,
          '',
        );

        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(
            offset: previousLineStart,
          ),
        );
      }

      // Continue bullet.
      const prefix = '• ';

      final updatedText = newText.replaceRange(
        cursor,
        cursor,
        prefix,
      );

      return TextEditingValue(
        text: updatedText,
        selection: TextSelection.collapsed(
          offset: cursor + prefix.length,
        ),
      );
    }

    // ==================================================
    // NUMBERED LIST
    // ==================================================

    final numberMatch = RegExp(
      r'^(\d+)\.\s+',
    ).firstMatch(previousLine);

    if (numberMatch != null) {
      final currentNumber =
          int.tryParse(
            numberMatch.group(1)!,
          ) ??
          1;

      final prefixLength =
          numberMatch.group(0)!.length;

      final content = previousLine.substring(
        prefixLength,
      );

      // Empty numbered item.
      if (content.trim().isEmpty) {
        final updatedText = newText.replaceRange(
          previousLineStart,
          cursor,
          '',
        );

        return TextEditingValue(
          text: updatedText,
          selection: TextSelection.collapsed(
            offset: previousLineStart,
          ),
        );
      }

      final nextNumber = currentNumber + 1;

      final prefix = '$nextNumber. ';

      final updatedText = newText.replaceRange(
        cursor,
        cursor,
        prefix,
      );

      return TextEditingValue(
        text: updatedText,
        selection: TextSelection.collapsed(
          offset: cursor + prefix.length,
        ),
      );
    }

    return newValue;
  }
}