import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class PptxSlide {
  final int index; // 1-based, for display
  final String text;
  const PptxSlide({required this.index, required this.text});
}

/// Minimal offline .pptx reader. Resolves the true slide order via
/// presentation.xml + its rels (slide file numbering isn't guaranteed to
/// match display order once slides are reordered/deleted in PowerPoint),
/// then pulls the text runs out of each slide's XML.
class PptxReader {
  static Future<List<PptxSlide>> read(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final slideFiles = _resolveSlideOrder(archive);
    final slides = <PptxSlide>[];

    for (var i = 0; i < slideFiles.length; i++) {
      final entry = archive.findFile(slideFiles[i]);
      if (entry == null) continue;
      slides.add(PptxSlide(index: i + 1, text: _extractSlideText(entry)));
    }

    if (slides.isEmpty) {
      throw const FormatException('No readable slides found in this file.');
    }

    return slides;
  }

  static List<String> _resolveSlideOrder(Archive archive) {
    try {
      final presEntry = archive.findFile('ppt/presentation.xml');
      final relsEntry = archive.findFile('ppt/_rels/presentation.xml.rels');
      if (presEntry == null || relsEntry == null) {
        return _fallbackSlideOrder(archive);
      }

      final relsDoc =
          XmlDocument.parse(utf8.decode(relsEntry.content as List<int>));
      final relMap = <String, String>{};
      for (final rel in relsDoc.findAllElements('Relationship')) {
        final id = rel.getAttribute('Id');
        final target = rel.getAttribute('Target');
        if (id != null && target != null) {
          relMap[id] = target.startsWith('slides/') ? 'ppt/$target' : target;
        }
      }

      final presDoc =
          XmlDocument.parse(utf8.decode(presEntry.content as List<int>));
      final orderedIds = presDoc
          .findAllElements('p:sldId')
          .map((e) => e.getAttribute('r:id'))
          .whereType<String>();

      final ordered =
          orderedIds.map((id) => relMap[id]).whereType<String>().toList();

      return ordered.isEmpty ? _fallbackSlideOrder(archive) : ordered;
    } catch (_) {
      return _fallbackSlideOrder(archive);
    }
  }

  static List<String> _fallbackSlideOrder(Archive archive) {
    final files = archive.files
        .map((f) => f.name)
        .where((name) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(name))
        .toList();

    files.sort((a, b) {
      final numA = int.parse(RegExp(r'\d+').firstMatch(a)!.group(0)!);
      final numB = int.parse(RegExp(r'\d+').firstMatch(b)!.group(0)!);
      return numA.compareTo(numB);
    });

    return files;
  }

  static String _extractSlideText(ArchiveFile entry) {
    final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));
    final paragraphs = <String>[];

    for (final p in doc.findAllElements('a:p')) {
      final buffer = StringBuffer();
      for (final t in p.findAllElements('a:t')) {
        buffer.write(t.innerText);
      }
      final text = buffer.toString().trim();
      if (text.isNotEmpty) paragraphs.add(text);
    }

    return paragraphs.join('\n');
  }
}