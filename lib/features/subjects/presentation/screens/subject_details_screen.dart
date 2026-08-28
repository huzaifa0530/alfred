import 'dart:async';
import 'dart:io';

import 'package:alfred/features/attachments/presentation/controllers/audio_providers.dart';
import 'package:alfred/features/attachments/presentation/widget/attachment_menu.dart';
import 'package:alfred/features/notes/presentation/controllers/notes_controller.dart';
import 'package:alfred/features/notes/presentation/screens/notes_screen.dart';
import 'package:alfred/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:alfred/features/subjects/presentation/screens/add_subject_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/subject.dart';
import '../controllers/subjects_providers.dart';

class SubjectDetailsScreen extends ConsumerWidget {
  final int subjectId;

  const SubjectDetailsScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(subjectsRepositoryProvider);

    return FutureBuilder<Subject?>(
      future: repository.getSubject(subjectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Subject not found', style: AppTextStyles.bodyMedium),
            ),
          );
        }

        final subject = snapshot.data!;

        return _SubjectDetailsContent(subject: subject);
      },
    );
  }
}

class _SubjectDetailsContent extends ConsumerStatefulWidget {
  final Subject subject;

  const _SubjectDetailsContent({required this.subject});

  @override
  ConsumerState<_SubjectDetailsContent> createState() =>
      _SubjectDetailsContentState();
}

class _SubjectDetailsContentState
    extends ConsumerState<_SubjectDetailsContent> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSending = false;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  final List<File> _pendingAttachments = [];

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
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  // ---- Attachment pickers ----

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
    if (image == null) return;
    setState(() => _pendingAttachments.add(File(image.path)));
  }

  Future<void> _pickGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return;
    setState(() => _pendingAttachments.add(File(image.path)));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    final files = result
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() => _pendingAttachments.addAll(files));
  }

  // ---- Voice recording ----

  Future<void> _startRecording() async {
    if (_isSending || _isRecording) return;

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
      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRecording) return;
        setState(() => _recordingDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to start recording: $e')));
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final recorder = ref.read(audioRecorderProvider);
      final path = await recorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      if (path == null || path.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording stopped, but no audio file was created.'),
          ),
        );
        return;
      }

      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file is empty or missing.')),
        );
        return;
      }

      setState(() => _pendingAttachments.add(file));
    } catch (e) {
      if (!mounted) return;
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
    if (!_isRecording) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    final recorder = ref.read(audioRecorderProvider);
    await recorder.cancel();

    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ---- Sending ----

  Future<void> _sendNote(NotesController controller) async {
    final text = _textController.text.trim();

    if (_isSending) return;
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await controller.createNoteWithAttachments(
        content: text,
        files: List<File>.from(_pendingAttachments),
      );

      if (!mounted) return;
      setState(() {
        _textController.clear();
        _pendingAttachments.clear();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Notes')));

      _focusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSubjectOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit subject'),
                onTap: () {
                  Navigator.pop(context);
                  _editSubject();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                title: const Text('Delete subject'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteSubject();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editSubject() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddSubjectScreen(subject: widget.subject),
      ),
    );

    if (updated == true && mounted) {
      // Subject changed elsewhere (name/color/etc) — pop back so the
      // subjects list (which streams live data) shows the fresh copy.
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteSubject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          'This will permanently delete "${widget.subject.name}" and all its notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(subjectsControllerProvider.notifier)
          .deleteSubject(widget.subject.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete subject: $e')));
    }
  }
  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final controller = ref.watch(notesControllerProvider(subject.id));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _SubjectAvatar(subject: subject),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall,
                  ),
                  if (subject.code != null)
                    Text(subject.code!, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
          IconButton(
            onPressed: () => _showSubjectOptions(context),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildWorkspace(context)),
          _buildComposer(controller),
        ],
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context) {
    final subject = widget.subject;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space20,
        AppDimensions.space20,
        AppDimensions.space20,
        AppDimensions.space20,
      ),
      children: [
        _buildDateDivider('TODAY'),
        const SizedBox(height: AppDimensions.space16),
        _buildWelcomeCard(),
        const SizedBox(height: AppDimensions.space20),
        _buildQuickActions(),
        const SizedBox(height: AppDimensions.space24),
        _buildSection(
          icon: Icons.forum_outlined,
          title: 'Notes',
          subtitle: 'Your explanations, thoughts and study notes',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotesScreen(
                  subjectId: subject.id,
                  subjectName: subject.name,
                ),
              ),
            );
          },
        ),
        _buildSection(
          icon: Icons.event_note_rounded,
          title: 'Upcoming',
          subtitle: 'Assignments, quizzes and important dates',
          onTap: () {},
        ),
        _buildSection(
          icon: Icons.check_circle_outline_rounded,
          title: 'Attendance',
          subtitle: 'Track your classes and attendance',
          onTap: () {},
        ),
        _buildSection(
          icon: Icons.analytics_outlined,
          title: 'Marks',
          subtitle: 'Quizzes, assignments, labs and exams',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildDateDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12,
          ),
          child: Text(text, style: AppTextStyles.labelSmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primarySoft,
              size: 21,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your knowledge space', style: AppTextStyles.headingSmall),
                SizedBox(height: AppDimensions.space6),
                Text(
                  'Save explanations, notes, photos, files and important information for this subject.',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.photo_camera_outlined,
            label: 'Photo',
            onTap: _pickCamera,
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: _QuickAction(
            icon: Icons.attach_file_rounded,
            label: 'File',
            onTap: _pickFile,
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: _QuickAction(
            icon: Icons.mic_none_rounded,
            label: 'Voice',
            onTap: _startRecording,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                  ),
                  child: Icon(icon, color: AppColors.primarySoft, size: 22),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headingSmall),
                      const SizedBox(height: AppDimensions.space4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Composer ----

  Widget _buildComposer(NotesController controller) {
    if (_isRecording) return _buildRecordingComposer();

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
                  onTap: () =>
                      setState(() => _pendingAttachments.removeAt(index)),
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
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          child: Column(
            children: [
              Icon(icon, size: 21, color: AppColors.primarySoft),
              const SizedBox(height: AppDimensions.space6),
              Text(label, style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectAvatar extends StatelessWidget {
  final Subject subject;

  const _SubjectAvatar({required this.subject});

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(subject.name);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primarySoft),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name
        .trim()
        .substring(0, name.trim().length >= 2 ? 2 : 1)
        .toUpperCase();
  }
}
