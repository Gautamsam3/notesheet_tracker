import 'package:flutter/material.dart';
import '../screens/notesheet/pdf_viewer.dart';

class PDFViewerWidget extends StatelessWidget {
  final String pdfUrl;
  final String fileName;

  const PDFViewerWidget({
    super.key,
    required this.pdfUrl,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final String viewId = 'pdf-view-${DateTime.now().millisecondsSinceEpoch}';
    
    return PDFViewer(
      url: pdfUrl,
      viewId: viewId,
    );
  }
}
