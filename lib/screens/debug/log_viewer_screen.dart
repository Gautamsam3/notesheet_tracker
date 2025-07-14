import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_logs/flutter_logs.dart';
import '../../services/logger_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _logger = AppLogger();
  List<String> _logFiles = [];
  String? _selectedLogContent;
  bool _isLoading = false;
  String _searchQuery = '';
  List<String> _filteredLogLines = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logger.uiInfo('🔍 LogViewerScreen initialized');
    _loadLogFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _logger.uiInfo('🔍 LogViewerScreen disposed');
    super.dispose();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);
    
    try {
      // FlutterLogs doesn't have a direct file listing method
      // We'll implement a simpler log viewer that shows current session logs
      _logger.info('📄 Loading current session logs');
      
      setState(() {
        _logFiles = ['Current Session'];
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      _logger.error('❌ Failed to load log files', error, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLogFileContent(String fileName) async {
    setState(() => _isLoading = true);
    
    try {
      // For now, we'll show a message about log viewing
      final content = '''
=== DevTools Log Viewer ===
Current session logging is active.

To view detailed logs:
1. Check the VS Code Debug Console for real-time logs
2. Use Flutter Inspector in DevTools
3. Check device logs with: flutter logs

Log Categories Available:
🔐 AUTH - Authentication events
🔥 FIRESTORE - Database operations  
🖥️ UI - User interface events
⚡ PERFORMANCE - Performance metrics
👤 USER_ACTION - User interactions
🧭 NAVIGATION - Screen navigation
🐛 DEBUG - Debug information
ℹ️ INFO - General information
⚠️ WARNING - Warning messages
❌ ERROR - Error messages
� FATAL - Fatal errors

DevTools Features Enabled:
- Performance overlay (toggle via DevTools)
- Widget inspector
- Network inspector
- Memory profiler
- CPU profiler
- Navigation logging
- Error boundary reporting

To export logs for debugging, use the export function.
      ''';
      
      _logger.info('📄 Showing DevTools log information');
      
      setState(() {
        _selectedLogContent = content;
        _isLoading = false;
      });
      
      _filterLogs();
    } catch (error, stackTrace) {
      _logger.error('❌ Failed to load log content for: $fileName', error, stackTrace);
      setState(() => _isLoading = false);
    }
  }

  void _filterLogs() {
    if (_selectedLogContent == null) return;
    
    final lines = _selectedLogContent!.split('\n');
    
    if (_searchQuery.isEmpty) {
      _filteredLogLines = lines;
    } else {
      _filteredLogLines = lines
          .where((line) => line.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    setState(() {});
    _logger.debug('🔍 Filtered logs: ${_filteredLogLines.length} lines match "$_searchQuery"');
  }

  Future<void> _exportLogs() async {
    try {
      _logger.info('📤 Starting log export...');
      // Use flutter_logs export functionality
      await FlutterLogs.exportLogs();
      _logger.info('📤✅ Logs exported successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error, stackTrace) {
      _logger.error('📤❌ Failed to export logs', error, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export logs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearLogs() async {
    try {
      _logger.info('🗑️ Clearing all logs...');
      await FlutterLogs.clearLogs();
      _logger.info('🗑️✅ Logs cleared successfully');
      
      setState(() {
        _logFiles.clear();
        _selectedLogContent = null;
        _filteredLogLines.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error, stackTrace) {
      _logger.error('🗑️❌ Failed to clear logs', error, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear logs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    _logger.userAction('copy_logs_to_clipboard', {
      'content_length': content.length,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getLogLevelColor(String line) {
    if (line.contains('FATAL') || line.contains('💀')) return Colors.red.shade300;
    if (line.contains('ERROR') || line.contains('❌')) return Colors.red.shade200;
    if (line.contains('WARNING') || line.contains('⚠️')) return Colors.orange.shade200;
    if (line.contains('INFO') || line.contains('ℹ️')) return Colors.blue.shade200;
    if (line.contains('DEBUG') || line.contains('🐛')) return Colors.grey.shade300;
    if (line.contains('AUTH') || line.contains('🔐')) return Colors.green.shade200;
    if (line.contains('FIRESTORE') || line.contains('🔥')) return Colors.purple.shade200;
    if (line.contains('UI') || line.contains('🖥️')) return Colors.cyan.shade200;
    if (line.contains('PERFORMANCE') || line.contains('⚡')) return Colors.yellow.shade200;
    return Colors.grey.shade100;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Log Viewer'),
        ),
        body: const Center(
          child: Text(
            'Log Viewer is only available in debug mode',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('DevTools - Log Viewer'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.web, size: 64, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Web Platform Detected',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'File-based logging is not available on web platform.\n\n'
                  'Please use browser developer tools or VS Code debug console for logging:\n\n'
                  '• Open browser DevTools (F12)\n'
                  '• Check Console tab for real-time logs\n'
                  '• Use VS Code Debug Console\n'
                  '• Enable Flutter DevTools for advanced debugging',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DevTools - Log Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
            tooltip: 'Refresh log files',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportLogs,
            tooltip: 'Export logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Logs'),
                  content: const Text('Are you sure you want to clear all logs?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearLogs();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Log files sidebar
                SizedBox(
                  width: 250,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Log Files',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _logFiles.length,
                            itemBuilder: (context, index) {
                              final fileName = _logFiles[index];
                              return ListTile(
                                title: Text(
                                  fileName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () => _loadLogFileContent(fileName),
                                dense: true,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Log content viewer
                Expanded(
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search logs...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    _searchQuery = value;
                                    _filterLogs();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_selectedLogContent != null)
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () => _copyToClipboard(_selectedLogContent!),
                                  tooltip: 'Copy all logs',
                                ),
                            ],
                          ),
                        ),
                        
                        // Log content
                        Expanded(
                          child: _selectedLogContent == null
                              ? const Center(
                                  child: Text('Select a log file to view its content'),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  itemCount: _filteredLogLines.length,
                                  itemBuilder: (context, index) {
                                    final line = _filteredLogLines[index];
                                    final color = _getLogLevelColor(line);
                                    
                                    return Container(
                                      color: color,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      child: SelectableText(
                                        line,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        
                        // Status bar
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            border: const Border(
                              top: BorderSide(color: Colors.grey),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Lines: ${_filteredLogLines.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                Text(
                                  'Filtered: "$_searchQuery"',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
