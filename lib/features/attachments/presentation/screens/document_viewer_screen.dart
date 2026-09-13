import 'package:alfred/features/attachments/presentation/widget/ask_ai_selection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/documents/docx_reader.dart';

import '../../../../core/documents/pptx_reader.dart';

import '../../../../core/documents/xlsx_reader.dart';
import '../../domain/entities/document_kind.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  final String path;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  String? _selectedText;
  late final DocumentKind _kind = classifyDocument(widget.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(child: _buildViewer()),
          if (_selectedText != null && _selectedText!.trim().isNotEmpty)
            AskAiSelectionBar(
              selectedText: _selectedText!,
              onDismiss: () => setState(() => _selectedText = null),
            ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    switch (_kind) {
      case DocumentKind.pdf:
        return PdfViewer.file(
          widget.path,
          params: PdfViewerParams(
            textSelectionParams: PdfTextSelectionParams(
              onTextSelectionChange: (selection) async {
                final text = await selection.getSelectedText();
                if (!mounted) return;
                setState(
                  () => _selectedText = text.trim().isEmpty ? null : text,
                );
              },
            ),
          ),
        );
      case DocumentKind.docx:
        return _DocxView(
          path: widget.path,
          onSelectionChanged: (text) => setState(() => _selectedText = text),
        );

      case DocumentKind.xlsx:
        return _XlsxView(
          path: widget.path,
          onSelectionChanged: (text) => setState(() => _selectedText = text),
        );

      case DocumentKind.pptx:
        return _PptxView(
          path: widget.path,
          onSelectionChanged: (text) => setState(() => _selectedText = text),
        );

      case DocumentKind.unsupported:
        return const Center(
          child: Text('This file type isn\'t supported yet.'),
        );
    }
  }
}

class _DocxView extends StatelessWidget {
  final String path;
  final ValueChanged<String?> onSelectionChanged;

  const _DocxView({required this.path, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: DocxReader.read(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not open this document: ${snapshot.error}'),
          );
        }
        return SelectionArea(
          onSelectionChanged: (selection) =>
              onSelectionChanged(selection?.plainText),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(snapshot.data ?? ''),
          ),
        );
      },
    );
  }
}

class _XlsxView extends StatelessWidget {
  final String path;
  final ValueChanged<String?> onSelectionChanged;

  const _XlsxView({required this.path, required this.onSelectionChanged});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<XlsxDocument>(
      future: XlsxReader.read(path),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not open this spreadsheet: ${snapshot.error}'),
          );
        }

        final sheets = snapshot.data!.sheets;

        return DefaultTabController(
          length: sheets.length,
          child: Column(
            children: [
              if (sheets.length > 1)
                TabBar(
                  isScrollable: true,
                  tabs: sheets.map((s) => Tab(text: s.name)).toList(),
                ),
              Expanded(
                child: TabBarView(
                  children: sheets.map((sheet) {
                    return SelectionArea(
                      onSelectionChanged: (selection) =>
                          onSelectionChanged(selection?.plainText),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: List.generate(
                              sheet.rows.isEmpty ? 0 : sheet.rows.first.length,
                              (i) => DataColumn(
                                label: Text(String.fromCharCode(65 + i)),
                              ),
                            ),
                            rows: sheet.rows
                                .map(
                                  (row) => DataRow(
                                    cells: row
                                        .map((c) => DataCell(Text(c)))
                                        .toList(),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PptxView extends StatefulWidget {
  final String path;
  final ValueChanged<String?> onSelectionChanged;

  const _PptxView({required this.path, required this.onSelectionChanged});

  @override
  State<_PptxView> createState() => _PptxViewState();
}

class _PptxViewState extends State<_PptxView> {
  late final Future<List<PptxSlide>> _future = PptxReader.read(widget.path);
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PptxSlide>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not read this presentation: ${snapshot.error}',
              ),
            ),
          );
        }

        final slides = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Slide ${_currentPage + 1} of ${slides.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return SelectionArea(
                    onSelectionChanged: (selection) =>
                        widget.onSelectionChanged(selection?.plainText),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        slide.text.isEmpty
                            ? '(No text on this slide)'
                            : slide.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
