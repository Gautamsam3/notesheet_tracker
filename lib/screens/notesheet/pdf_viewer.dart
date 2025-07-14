import 'package:flutter/material.dart';

// Web implementation
export 'pdf_viewer_web.dart' if (dart.library.html) 'pdf_viewer_web.dart'
    if (dart.library.io) 'pdf_viewer_mobile.dart'; 