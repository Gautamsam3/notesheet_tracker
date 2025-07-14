import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewer extends StatelessWidget {
  final String url;
  final String viewId; // Not used in mobile implementation

  const PDFViewer({
    super.key,
    required this.url,
    required this.viewId,
  });

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.network(
      url,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load PDF: ${details.description}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
} 