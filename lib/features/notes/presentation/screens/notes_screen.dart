import 'dart:async';
import 'dart:io';

import 'package:alfred/features/attachments/presentation/controllers/attachment_controller.dart';
import 'package:alfred/features/attachments/presentation/controllers/audio_providers.dart';
import 'package:alfred/features/attachments/presentation/widget/attachment_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  bool _isSending = false;

  File? _pendingFile;
  String? _pendingType;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  String? _pendingAudioPath;

  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _pendingAttachments = [];
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
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);

    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(notesControllerProvider(widget.subjectId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.subjectName, style: AppTextStyles.headingSmall),
            const Text('Notes', style: AppTextStyles.bodySmall),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space20,
        AppDimensions.space16,
        AppDimensions.space20,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

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
              onDelete: () => _confirmDelete(note),
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
                    style: const TextStyle(color: Colors.white),

                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendNote(controller),
                    decoration: InputDecoration(
                      hintText: 'Write a note...',
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
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
                              : const Icon(Icons.arrow_upward_rounded),
                        )
                      : IconButton(
                          key: const ValueKey('voice'),
                          onPressed: _startRecording,
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

    if (_isSending) {
      return;
    }

    if (text.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await controller.createNoteWithAttachments(
        content: text,
        files: List<File>.from(_pendingAttachments),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _textController.clear();
        _pendingAttachments.clear();
      });

      _focusNode.requestFocus();
    } catch (e, stackTrace) {
      debugPrint('SEND NOTE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
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
