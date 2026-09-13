import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class XlsxSheet {
  final String name;
  final List<List<String>> rows;
  const XlsxSheet({required this.name, required this.rows});
}

class XlsxDocument {
  final List<XlsxSheet> sheets;
  const XlsxDocument(this.sheets);
}

/// Minimal offline .xlsx reader: unzips the file and parses the raw
/// OOXML sheet/sharedStrings XML directly, avoiding the `excel` package
/// (which pins an incompatible old `archive` version).
class XlsxReader {
  static Future<XlsxDocument> read(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final sharedStrings = _readSharedStrings(archive);
    final sheetNames = _readSheetNames(archive);
    final sheets = <XlsxSheet>[];

    for (var i = 0; i < sheetNames.length; i++) {
      final entry = archive.findFile('xl/worksheets/sheet${i + 1}.xml');
      if (entry == null) continue;
      sheets.add(XlsxSheet(
        name: sheetNames[i],
        rows: _readSheetRows(entry, sharedStrings),
      ));
    }

    if (sheets.isEmpty) {
      throw const FormatException('No readable sheets found in this file.');
    }

    return XlsxDocument(sheets);
  }

  static List<String> _readSharedStrings(Archive archive) {
    final entry = archive.findFile('xl/sharedStrings.xml');
    if (entry == null) return [];

    final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));
    return doc.findAllElements('si').map((si) {
      return si.findAllElements('t').map((t) => t.innerText).join();
    }).toList();
  }

  static List<String> _readSheetNames(Archive archive) {
    final entry = archive.findFile('xl/workbook.xml');
    if (entry == null) return ['Sheet1'];

    final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));
    final names = doc
        .findAllElements('sheet')
        .map((e) => e.getAttribute('name') ?? 'Sheet')
        .toList();

    return names.isEmpty ? ['Sheet1'] : names;
  }

  static List<List<String>> _readSheetRows(
    ArchiveFile entry,
    List<String> sharedStrings,
  ) {
    final doc = XmlDocument.parse(utf8.decode(entry.content as List<int>));
    final rows = <List<String>>[];

    for (final rowEl in doc.findAllElements('row')) {
      final cells = <int, String>{};
      var maxCol = 0;

      for (final c in rowEl.findElements('c')) {
        final ref = c.getAttribute('r') ?? '';
        final col = _columnIndexFromRef(ref);
        final type = c.getAttribute('t');
        String value = '';

        if (type == 's') {
          final idx = int.tryParse(c.getElement('v')?.innerText ?? '');
          if (idx != null && idx >= 0 && idx < sharedStrings.length) {
            value = sharedStrings[idx];
          }
        } else if (type == 'inlineStr') {
          value = c
                  .getElement('is')
                  ?.findAllElements('t')
                  .map((t) => t.innerText)
                  .join() ??
              '';
        } else {
          value = c.getElement('v')?.innerText ?? '';
        }

        cells[col] = value;
        if (col > maxCol) maxCol = col;
      }

      rows.add(List<String>.generate(maxCol + 1, (i) => cells[i] ?? ''));
    }

    return rows;
  }

  static int _columnIndexFromRef(String ref) {
    final letters = ref.replaceAll(RegExp(r'[0-9]'), '');
    var index = 0;
    for (var i = 0; i < letters.length; i++) {
      index = index * 26 + (letters.codeUnitAt(i) - 64);
    }
    return index - 1;
  }
}