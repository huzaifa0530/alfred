import 'package:flutter/material.dart';

import '../../../subjects/domain/entities/subject.dart';

import '../../domain/entities/mark.dart';
import '../../domain/entities/mark_component.dart';

import 'marks_component_header.dart';
import 'marks_subject_row.dart';

class MarksGrid extends StatelessWidget {
  final Subject subject;
  final List<MarkComponent> components;
  final List<Mark> marks;

  const MarksGrid({
    super.key,
    required this.subject,
    required this.components,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================

          Row(
            children: [
              Container(
                width: 150,
                height: 82,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Text(
                  'Subject',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),

              ...components.map(
                (component) {
                  return MarksComponentHeader(
                    component: component,
                  );
                },
              ),
            ],
          ),

          // ====================================================
          // SUBJECT ROW
          // ====================================================

          MarksSubjectRow(
            subject: subject,
            components: components,
            marks: marks,
          ),
        ],
      ),
    );
  }
}