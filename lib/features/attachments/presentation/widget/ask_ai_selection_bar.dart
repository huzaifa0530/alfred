import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/ai/ai_providers.dart'; // confirm this exposes aiClientProvider

class AskAiSelectionBar extends ConsumerStatefulWidget {
  final String selectedText;
  final VoidCallback onDismiss;

  const AskAiSelectionBar({
    super.key,
    required this.selectedText,
    required this.onDismiss,
  });

  @override
  ConsumerState<AskAiSelectionBar> createState() => _AskAiSelectionBarState();
}

class _AskAiSelectionBarState extends ConsumerState<AskAiSelectionBar> {
  bool _isAsking = false;

  Future<void> _askAi(String instruction) async {
    setState(() => _isAsking = true);

    try {
      final aiClient = ref.read(geminiClientProvider);

      final prompt =
          '$instruction\n\n---\n${widget.selectedText}\n---\n'
          'Keep the answer concise and directly useful.';

      final answer = await aiClient.generateText(prompt);

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
    children: [
  Text('Alfred', style: AppTextStyles.headingSmall),
  const SizedBox(height: 12),
  MarkdownBody(
    data: answer,
    selectable: true,
  ),
],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ask Alfred failed: $e')));
    } finally {
      if (mounted) setState(() => _isAsking = false);
    }
  }

  Future<void> _askCustomQuestion() async {
    final controller = TextEditingController();

    final question = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask about this text', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. "Translate this to Urdu" or "Give an example"',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Ask'),
              ),
            ),
          ],
        ),
      ),
    );

    if (question == null || question.trim().isEmpty) return;
    if (!mounted) return;

    await _askAi(question.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.selectedText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            if (_isAsking)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                tooltip: 'Ask your own question',
                onPressed: _askCustomQuestion,
                icon: const Icon(Icons.edit_note_rounded),
              ),
              TextButton(
                onPressed: () => _askAi('Explain this passage simply:'),
                child: const Text('Explain'),
              ),
              TextButton(
                onPressed: () => _askAi('Summarize this passage:'),
                child: const Text('Summarize'),
              ),
            ],
            IconButton(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}