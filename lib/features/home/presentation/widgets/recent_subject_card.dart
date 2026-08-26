import 'package:flutter/material.dart';

import '../../../subjects/domain/entities/subject.dart';

class RecentSubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;

  const RecentSubjectCard({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme
                .colorScheme
                .surfaceContainer,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: theme
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  subject.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}