import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// --- SUPABASE CONFIGURATION ---
// Replace with your actual Supabase URL and Anon Key
const String supabaseUrl = 'https://fqdyhiejagolscwtmmly.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZxZHloaWVqYWdvbHNjd3RtbWx5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI4NTE1NDcsImV4cCI6MjA2ODQyNzU0N30.bX5LfrqC-Jogz1x8vJbmRfrCky_INWWlghbkZ9vgrZA';

/*************  ✨ Windsurf Command ⭐  *************/
/// Initializes the app.
///
/// Ensures that the widgets are bound to the flutter engine, then
/// initializes the Supabase client with the provided URL and anon key.
/// Finally, runs the app with the root widget `MyApp`.
/*******  ec8bf8e4-72e9-4884-be59-7f0de90ee928  *******/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Flow Manager',
      theme: _buildTheme(context),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- THEME DEFINITION ---
ThemeData _buildTheme(BuildContext context) {
  final baseTheme = ThemeData.light(useMaterial3: true);
  return baseTheme.copyWith(
    primaryColor: const Color(0xFF00796B), // Teal
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF00796B), // Teal
      secondary: Color(0xFF3F51B5), // Indigo
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF333333),
      error: Color(0xFFD32F2F),
      background: Color(0xFFF5F7FA),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00796B),
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey[700]),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.session != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.document_scanner_outlined,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Document Flow Manager',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please sign in to continue',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email ID',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- DASHBOARD SCREEN (MODIFIED FOR TEXT-BASED WORKFLOW) ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _studentNameController = TextEditingController();
  final _projectDetailsController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedReviewer;
  String? _userEmail;
  String? _userRole;
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  final List<String> _reviewers = [
    'Reviewer 1 (rev1@gmail.com)',
    'Reviewer 2 (rev2@gmail.com)',
    'Reviewer 3 (rev3@gmail.com)',
    'Reviewer 4 (rev4@gmail.com)',
    'Reviewer 5 (rev5@gmail.com)',
  ];
  final String _hodEmail = 'hod@gmail.com';

  @override
  void initState() {
    super.initState();
    _initializeUserAndData();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _projectDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserAndData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _userEmail = user.email;
      _userRole = _getRoleFromEmail(user.email!);
    });
    await _fetchSubmissions();
  }

  String _getRoleFromEmail(String email) {
    if (email.startsWith('rev')) return 'reviewer';
    if (email == _hodEmail) return 'hod';
    return 'submitter';
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields.', isError: true);
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('documents').insert({
        'student_name': _studentNameController.text.trim(),
        'project_details': _projectDetailsController.text.trim(),
        'reviewer_email': _selectedReviewer,
        'status': 'Under Review',
        'submitter_email': _userEmail,
        'notes': _notesController.text.trim(),
        'user_id': user.id,
      });

      _showSnackBar('Details submitted successfully!', isError: false);
      _resetForm();
      _fetchSubmissions();
    } catch (e) {
      _showSnackBar('Error submitting details: ${e.toString()}', isError: true);
    }
  }

  Future<void> _updateDocumentStatus(String docId, String newStatus) async {
    try {
      String nextReviewerEmail = '';
      String statusUpdate = '';

      if (_userRole == 'reviewer') {
        if (newStatus == 'Approved') {
          statusUpdate = 'Forwarded to HOD';
          nextReviewerEmail = _hodEmail;
        } else {
          // Needs Revision
          statusUpdate = 'Needs Revision';
        }
      } else if (_userRole == 'hod') {
        statusUpdate = newStatus; // 'Approved' or 'Needs Revision'
      }

      final updateData = {'status': statusUpdate};
      if (nextReviewerEmail.isNotEmpty) {
        updateData['reviewer_email'] = nextReviewerEmail;
      }

      await Supabase.instance.client
          .from('documents')
          .update(updateData)
          .eq('id', docId);

      _showSnackBar('Status updated.', isError: false);
      _fetchSubmissions();
    } catch (e) {
      _showSnackBar('Error updating status: ${e.toString()}', isError: true);
    }
  }

  Future<void> _fetchSubmissions() async {
    if (_userEmail == null) return;
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client.from('documents').select('*');

      if (_userRole == 'submitter') {
        query = query.eq('submitter_email', _userEmail!);
      } else if (_userRole == 'reviewer') {
        query = query
            .eq('reviewer_email', _userEmail!)
            .eq('status', 'Under Review');
      } else if (_userRole == 'hod') {
        query = query
            .eq('reviewer_email', _hodEmail)
            .eq('status', 'Forwarded to HOD');
      }

      final data = await query;

      if (mounted) {
        setState(() {
          _submissions = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Error fetching submissions: ${e.toString()}',
          isError: true,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _studentNameController.clear();
    _projectDetailsController.clear();
    _notesController.clear();
    setState(() {
      _selectedReviewer = null;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green[600],
      ),
    );
  }

  String _getDashboardTitle() {
    switch (_userRole) {
      case 'hod':
        return 'HOD Dashboard';
      case 'reviewer':
        return 'Reviewer Dashboard';
      default:
        return 'My Submissions';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getDashboardTitle()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _signOut();
            },
            icon: const Icon(Icons.account_circle, size: 28),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userEmail ?? 'Loading...',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _userRole?.toUpperCase() ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSubmissions,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_userRole == 'submitter') _buildSubmitterForm(),
              const SizedBox(height: 16),
              _buildSubmissionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitterForm() {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Submission',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(labelText: 'Student Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter student name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _projectDetailsController,
                decoration: const InputDecoration(labelText: 'Project Details'),
                maxLines: 4,
                validator: (v) => v == null || v.isEmpty
                    ? 'Please enter project details'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedReviewer,
                decoration: const InputDecoration(labelText: 'Assign Reviewer'),
                items: _reviewers.map((String reviewer) {
                  final email = reviewer.substring(
                    reviewer.indexOf('(') + 1,
                    reviewer.indexOf(')'),
                  );
                  return DropdownMenuItem<String>(
                    value: email,
                    child: Text(reviewer),
                  );
                }).toList(),
                onChanged: (String? newValue) =>
                    setState(() => _selectedReviewer = newValue),
                validator: (v) => v == null ? 'Please select a reviewer' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Add any relevant notes for the reviewer...',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitDetails,
                  child: const Text('Submit for Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Submissions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_submissions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _userRole == 'submitter'
                            ? 'You have no submissions'
                            : 'No submissions requiring your review',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _submissions.length,
                itemBuilder: (context, index) {
                  final submission = _submissions[index];
                  return _buildSubmissionTile(submission);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionTile(Map<String, dynamic> submission) {
    final status = submission['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final title = submission['student_name'] ?? 'No Name';
    final details = submission['project_details'] ?? 'No details';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_userRole == 'reviewer' || _userRole == 'hod')
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      _updateDocumentStatus(submission['id'].toString(), value);
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem(
                          value: 'Approved',
                          child: Text(
                            _userRole == 'reviewer'
                                ? 'Forward to HOD'
                                : 'Approve',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Needs Revision',
                          child: Text('Reject'),
                        ),
                      ];
                    },
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.description_outlined, 'Details', details),
            _buildInfoRow(
              Icons.calendar_today,
              'Submitted on',
              DateFormat(
                'dd MMM yyyy',
              ).format(DateTime.parse(submission['created_at'])),
            ),
            if (_userRole != 'submitter')
              _buildInfoRow(
                Icons.person_outline,
                'Submitter',
                submission['submitter_email'],
              ),
            _buildInfoRow(
              Icons.person_pin_outlined,
              'Reviewer',
              submission['reviewer_email'],
            ),
            if (submission['notes'] != null && submission['notes'].isNotEmpty)
              _buildInfoRow(Icons.notes_outlined, 'Notes', submission['notes']),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green[700]!;
      case 'Needs Revision':
        return Colors.red[700]!;
      case 'Forwarded to HOD':
        return Colors.purple[700]!;
      case 'Under Review':
        return Colors.orange[800]!;
      default:
        return Colors.grey[700]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Approved':
        return Icons.check_circle_outline;
      case 'Needs Revision':
        return Icons.cancel_outlined;
      case 'Forwarded to HOD':
        return Icons.double_arrow_outlined;
      case 'Under Review':
        return Icons.hourglass_top_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
