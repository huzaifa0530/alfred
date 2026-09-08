import 'package:flutter/material.dart';

class FormattedNoteText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const FormattedNoteText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: style,
        children: _buildDocument(text),
      ),
    );
  }

  List<InlineSpan> _buildDocument(String text) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // ================================
      // BULLET LIST
      // ================================
      if (line.startsWith('• ')) {
        spans.add(
          TextSpan(
            text: '• ',
            style: style.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );

        spans.addAll(
          _parseInline(
            line.substring(2),
            style,
          ),
        );
      }

      // ================================
      // NUMBERED LIST
      // ================================
      else {
        final numberMatch = RegExp(
          r'^(\d+)\.\s',
        ).firstMatch(line);

        if (numberMatch != null) {
          final prefix = numberMatch.group(0)!;

          spans.add(
            TextSpan(
              text: prefix,
              style: style.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          );

          spans.addAll(
            _parseInline(
              line.substring(prefix.length),
              style,
            ),
          );
        }

        // ================================
        // NORMAL TEXT
        // ================================
        else {
          spans.addAll(
            _parseInline(
              line,
              style,
            ),
          );
        }
      }

      if (i < lines.length - 1) {
        spans.add(
          const TextSpan(text: '\n'),
        );
      }
    }

    return spans;
  }

  List<InlineSpan> _parseInline(
    String text,
    TextStyle currentStyle,
  ) {
    final spans = <InlineSpan>[];

    int index = 0;
    int plainStart = 0;

    while (index < text.length) {
      final char = text[index];

      if (char != '*' && char != '_' && char != '~') {
        index++;
        continue;
      }

      final closingIndex = text.indexOf(
        char,
        index + 1,
      );

      if (closingIndex == -1 ||
          closingIndex <= index + 1) {
        index++;
        continue;
      }

      // Add normal text before marker.
      if (index > plainStart) {
        spans.add(
          TextSpan(
            text: text.substring(
              plainStart,
              index,
            ),
            style: currentStyle,
          ),
        );
      }

      final innerText = text.substring(
        index + 1,
        closingIndex,
      );

      TextStyle formattedStyle;

      switch (char) {
        case '*':
          formattedStyle = currentStyle.copyWith(
            fontWeight: FontWeight.bold,
          );
          break;

        case '_':
          formattedStyle = currentStyle.copyWith(
            fontStyle: FontStyle.italic,
          );
          break;

        case '~':
          formattedStyle = currentStyle.copyWith(
            decoration: TextDecoration.lineThrough,
          );
          break;

        default:
          formattedStyle = currentStyle;
      }

      // Parse again so combinations work:
      //
      // *_hello_*
      // _*hello*_
      // ~*hello*~
      //
      spans.addAll(
        _parseInline(
          innerText,
          formattedStyle,
        ),
      );

      index = closingIndex + 1;
      plainStart = index;
    }

    // Remaining normal text.
    if (plainStart < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(plainStart),
          style: currentStyle,
        ),
      );
    }

    return spans;
  }
}