import 'package:flutter/material.dart';
import 'dart:html' as html;
// Import for web platform views
import 'dart:ui_web' as ui_web;

class PDFViewer extends StatelessWidget {
  final String url;
  final String viewId;

  const PDFViewer({
    super.key,
    required this.url,
    required this.viewId,
  });

  @override
  Widget build(BuildContext context) {
    // Register the view factory
    ui_web.platformViewRegistry.registerViewFactory(
      viewId, 
      (int viewId) => html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..allowFullscreen = true
    );

    return HtmlElementView(viewType: viewId);
  }
} 