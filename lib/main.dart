import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Review Dashboard',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.blue[700]),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
      ),

      themeMode: _themeMode,

      home: DashboardScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleDarkMode: _toggleTheme,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const DashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? selectedFileName;
  String? selectedFilePath;
  String? selectedReviewer;
  final TextEditingController _notesController = TextEditingController();

  final List<String> reviewers = [
    'John Smith - Senior Manager',
    'Sarah Johnson - Team Lead',
    'Mike Davis - Project Manager',
    'Emily Brown - Quality Assurance',
    'David Wilson - Technical Lead',
  ];

  final List<Map<String, dynamic>> recentSubmissions = [
    {
      'document': 'Project_Proposal.pdf',
      'reviewer': 'John Smith',
      'status': 'Under Review',
      'date': '2024-01-15',
      'statusColor': Colors.orange,
    },
    {
      'document': 'Budget_Report.xlsx',
      'reviewer': 'Sarah Johnson',
      'status': 'Approved',
      'date': '2024-01-14',
      'statusColor': Colors.green,
    },
    {
      'document': 'Technical_Specs.docx',
      'reviewer': 'Mike Davis',
      'status': 'Needs Revision',
      'date': '2024-01-13',
      'statusColor': Colors.red,
    },
  ];

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        selectedFilePath = result.files.single.path;
      });
    }
  }

  void _submitDocument() {
    if (selectedFileName == null || selectedReviewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document and a reviewer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      recentSubmissions.insert(0, {
        'document': selectedFileName!,
        'reviewer': selectedReviewer!.split(' - ')[0],
        'status': 'Under Review',
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'statusColor': Colors.orange,
      });
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Document submitted successfully for review!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      selectedFileName = null;
      selectedFilePath = null;
      selectedReviewer = null;
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme.of(context) to get current theme colors
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      // The scaffold background color is now handled by the theme
      appBar: AppBar(
        title: const Text('Document Review Dashboard'),
        // AppBar colors are now handled by the theme
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
            tooltip: widget.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Submit New Document',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select Document'),
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (selectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Chip(
                          label: Text(
                            selectedFileName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () =>
                              setState(() => selectedFileName = null),
                          avatar: const Icon(Icons.insert_drive_file),
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedReviewer,
                      onChanged: (newValue) {
                        setState(() => selectedReviewer = newValue);
                      },
                      items: reviewers.map((reviewer) {
                        return DropdownMenuItem(
                          value: reviewer,
                          child: Text(reviewer),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Assign Reviewer',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Submit for Review'),
                      onPressed: _submitDocument,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Submissions',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentSubmissions.length,
              itemBuilder: (context, index) {
                final item = recentSubmissions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.description, size: 30),
                    title: Text(
                      item['document'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'To: ${item['reviewer']} on ${item['date']}',
                      style: TextStyle(color: textColor?.withOpacity(0.7)),
                    ),
                    trailing: Chip(
                      label: Text(
                        item['status'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: item['statusColor'],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
