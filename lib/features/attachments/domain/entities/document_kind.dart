enum DocumentKind { pdf, docx, xlsx, pptx, unsupported }

DocumentKind classifyDocument(String path) {
  final ext = path.toLowerCase().split('.').last;
  switch (ext) {
    case 'pdf':
      return DocumentKind.pdf;
    case 'docx':
      return DocumentKind.docx;
    case 'xlsx':
    case 'xls':
    case 'csv':
      return DocumentKind.xlsx;
    case 'pptx':
    case 'ppt':
      return DocumentKind.pptx;
    default:
      return DocumentKind.unsupported;
  }
}