import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notesheet_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../services/supabase_admin_service.dart';

class EditNotesheetScreen extends StatefulWidget {
  final Notesheet notesheet;

  const EditNotesheetScreen({
    super.key,
    required this.notesheet,
  });

  @override
  State<EditNotesheetScreen> createState() => _EditNotesheetScreenState();
}

class _EditNotesheetScreenState extends State<EditNotesheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final SupabaseAdminService _adminService = SupabaseAdminService();

  List<AppUser> _availableReviewers = [];
  List<AppUser> _selectedReviewers = [];
  DateTime? _selectedDeadline;
  bool _isLoading = false;
  bool _isLoadingReviewers = true;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadReviewers();
  }

  void _initializeFields() {
    _titleController.text = widget.notesheet.title;
    _descriptionController.text = widget.notesheet.description;
    _selectedDeadline = widget.notesheet.deadline;
    
    // Convert current reviewers to selected reviewers
    _selectedReviewers = widget.notesheet.reviewFlow.map((reviewer) => AppUser(
      uid: reviewer.uid,
      name: reviewer.name,
      email: '', // We don't have email in reviewer model
      role: UserRole.reviewer,
      department: '',
      createdAt: DateTime.now(),
    )).toList();
  }

  Future<void> _loadReviewers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final reviewers = await _adminService.getAvailableReviewers();
      
      setState(() {
        _availableReviewers = reviewers.where((reviewer) => 
          reviewer.uid != userProvider.currentUser?.uid).toList();
        _isLoadingReviewers = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviewers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviewers: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.deepPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  Future<void> _updateNotesheet() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReviewers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one reviewer')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _databaseService.updateNotesheet(
        notesheetId: widget.notesheet.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: _selectedDeadline,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notesheet updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Error updating notesheet: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating notesheet: $e')),

        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Notesheet'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showVersionHistory(),
              tooltip: 'View Edit History',
            ),
          ),
        ],
      ),
      body: _isLoadingReviewers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Edit warning card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Editing Notice',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Editing will restart the review process with all reviewers',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title field
                    _buildSectionCard(
                      icon: Icons.title,
                      title: 'Title',
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Enter notesheet title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description field
                    _buildSectionCard(
                      icon: Icons.description,
                      title: 'Description',
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Enter detailed description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Description must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reviewers selection
                    _buildSectionCard(
                      icon: Icons.people,
                      title: 'Reviewers',
                      child: Column(
                        children: [
                          // Selected reviewers
                          if (_selectedReviewers.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Reviewers (${_selectedReviewers.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _selectedReviewers.map((reviewer) {
                                      return Chip(
                                        label: Text(reviewer.name),
                                        deleteIcon: const Icon(Icons.close, size: 18),
                                        onDeleted: () {
                                          setState(() {
                                            _selectedReviewers.remove(reviewer);
                                          });
                                        },
                                        backgroundColor: Colors.green.shade100,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          // Add reviewer button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showReviewerSelection,
                              icon: const Icon(Icons.person_add),
                              label: Text(_selectedReviewers.isEmpty 
                                  ? 'Select Reviewers' 
                                  : 'Add More Reviewers'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Deadline selection
                    _buildSectionCard(
                      icon: Icons.event,
                      title: 'Deadline (Optional)',
                      child: InkWell(
                        onTap: _selectDeadline,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDeadline != null
                                      ? DateFormat('EEEE, MMM dd, yyyy').format(_selectedDeadline!)
                                      : 'Select deadline (optional)',
                                  style: TextStyle(
                                    color: _selectedDeadline != null 
                                        ? Colors.grey.shade800 
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              if (_selectedDeadline != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDeadline = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateNotesheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Update Notesheet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.deepPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showReviewerSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Reviewers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _availableReviewers.length,
                itemBuilder: (context, index) {
                  final reviewer = _availableReviewers[index];
                  final isSelected = _selectedReviewers.any((r) => r.uid == reviewer.uid);
                  
                  return ListTile(
                    title: Text(reviewer.name),
                    subtitle: Text(reviewer.department),
                    trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.radio_button_unchecked),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedReviewers.removeWhere((r) => r.uid == reviewer.uid);
                        } else {
                          _selectedReviewers.add(reviewer);
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVersionHistory() async {
    try {
      final versions = await _databaseService.getNotesheetVersions(widget.notesheet.id);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit History'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current version
                _buildVersionItem(
                  version: 'Current Version',
                  date: widget.notesheet.updatedAt ?? widget.notesheet.createdAt,
                  title: widget.notesheet.title,
                  description: widget.notesheet.description,
                  isOriginal: false,
                  isCurrent: true,
                ),
                // Previous versions
                ...versions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final versionData = entry.value;
                  return _buildVersionItem(
                    version: index == versions.length - 1 ? 'Original' : 'Version ${versions.length - index}',
                    date: versionData.updatedAt ?? versionData.createdAt,
                    title: versionData.title,
                    description: versionData.description,
                    isOriginal: index == versions.length - 1,
                    isCurrent: false,
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading version history: $e')),
        );
      }
    }
  }

  Widget _buildVersionItem({
    required String version,
    required DateTime date,
    required String title,
    required String description,
    required bool isOriginal,
    bool isCurrent = false,
  }) {
    final color = isCurrent 
        ? Colors.green 
        : isOriginal 
            ? Colors.blue 
            : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        leading: Icon(
          isCurrent ? Icons.check_circle : isOriginal ? Icons.create : Icons.edit,
          color: color,
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    version,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.shade800,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: $title',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Description: $description',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
