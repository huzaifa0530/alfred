import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Minimal offline .docx reader: extracts paragraph text from
/// word/document.xml. Loses rich formatting (bold/italic/tables) but is
/// dependency-light, fully offline, and gives us plain, selectable text.
class DocxReader {
  static Future<String> read(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final entry = archive.findFile('word/document.xml');
    if (entry == null) {
      throw const FormatException('This file does not look like a valid .docx.');
    }

    final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));
    final paragraphs = <String>[];

    for (final p in doc.findAllElements('w:p')) {
      final buffer = StringBuffer();
      for (final t in p.findAllElements('w:t')) {
        buffer.write(t.innerText);
      }
      paragraphs.add(buffer.toString());
    }

    return paragraphs.join('\n\n');
  }
}