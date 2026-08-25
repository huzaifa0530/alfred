import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/subject.dart';
import '../controllers/subjects_controller.dart';

class AddSubjectScreen extends ConsumerStatefulWidget {
  const AddSubjectScreen({super.key, this.subject});

  final Subject? subject;

  bool get isEditing => subject != null;

  @override
  ConsumerState<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends ConsumerState<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _instructorController;
  late final TextEditingController _roomController;

  String _selectedColor = '#7C5CFF';
  bool _isSaving = false;

  static const _colors = [
    '#7C5CFF',
    '#4DA3FF',
    '#35C98A',
    '#F4B740',
    '#FF5C6C',
    '#E879F9',
  ];

  @override
  void initState() {
    super.initState();

    final subject = widget.subject;

    _nameController = TextEditingController(text: subject?.name ?? '');

    _codeController = TextEditingController(text: subject?.code ?? '');

    _instructorController = TextEditingController(
      text: subject?.instructor ?? '',
    );

    _roomController = TextEditingController(text: subject?.room ?? '');
    _nameController.addListener(_refreshPreview);
    _codeController.addListener(_refreshPreview);
    _selectedColor = subject?.color ?? '#7C5CFF';
  }

  void _refreshPreview() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshPreview);
    _codeController.removeListener(_refreshPreview);

    _nameController.dispose();
    _codeController.dispose();
    _instructorController.dispose();
    _roomController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit subject' : 'New subject')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space20,
              AppDimensions.space16,
              AppDimensions.space20,
              AppDimensions.space40,
            ),
            children: [
              _buildPreview(),

              const SizedBox(height: AppDimensions.space32),

              _buildSectionTitle('Basic information'),

              const SizedBox(height: AppDimensions.space12),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Subject name',
                  hintText: 'e.g. Operating Systems',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject name is required';
                  }

                  if (value.trim().length < 2) {
                    return 'Enter a valid subject name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: AppDimensions.space16),

              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Subject code',
                  hintText: 'e.g. SE-305',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),

              const SizedBox(height: AppDimensions.space32),

              _buildSectionTitle('Class information'),

              const SizedBox(height: AppDimensions.space12),

              TextFormField(
                controller: _instructorController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Instructor',
                  hintText: 'e.g. Dr. Ahmed',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  hintText: 'e.g. Lab 3',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
              ),

              const SizedBox(height: AppDimensions.space32),

              _buildSectionTitle('Appearance'),

              const SizedBox(height: AppDimensions.space12),

              _buildColorSelector(),

              const SizedBox(height: AppDimensions.space40),

              SizedBox(
                height: AppDimensions.buttonHeight,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveSubject,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save changes' : 'Create subject'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final name = _nameController.text.trim();

    final initials = _getInitials(name.isEmpty ? 'Subject' : name);

    final color = _parseColor(_selectedColor);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTextStyles.labelLarge.copyWith(
                color: color,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: AppDimensions.space16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Subject name' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall,
                ),

                const SizedBox(height: AppDimensions.space4),

                Text(
                  _codeController.text.trim().isEmpty
                      ? 'Subject code'
                      : _codeController.text.trim(),
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1),
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: AppDimensions.space12,
      runSpacing: AppDimensions.space12,
      children: _colors.map((hex) {
        final color = _parseColor(hex);
        final selected = hex == _selectedColor;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedColor = hex;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? color : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final controller = ref.read(subjectsControllerProvider.notifier);

      if (widget.subject == null) {
        await controller.createSubject(
          name: _nameController.text,
          code: _codeController.text,
          instructor: _instructorController.text,
          room: _roomController.text,
          color: _selectedColor,
        );
      } else {
        await controller.updateSubject(
          widget.subject!.copyWith(
            name: _nameController.text.trim(),
            code: _emptyToNull(_codeController.text),
            instructor: _emptyToNull(_instructorController.text),
            room: _emptyToNull(_roomController.text),
            color: _selectedColor,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.subject == null ? 'Subject created' : 'Subject updated',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _emptyToNull(String value) {
    final cleaned = value.trim();

    return cleaned.isEmpty ? null : cleaned;
  }

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return '?';
    }

    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  Color _parseColor(String value) {
    try {
      final hex = value.replaceFirst('#', '');

      return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
