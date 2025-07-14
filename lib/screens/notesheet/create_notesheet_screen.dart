import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../services/supabase_admin_service.dart';
import '../../services/pdf_upload_service.dart';
import '../../models/user_model.dart';

class CreateNotesheetScreen extends StatefulWidget {
  const CreateNotesheetScreen({super.key});

  @override
  State<CreateNotesheetScreen> createState() => _CreateNotesheetScreenState();
}

class _CreateNotesheetScreenState extends State<CreateNotesheetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final SupabaseAdminService _adminService = SupabaseAdminService();
  
  List<AppUser> _availableReviewers = [];
  final List<AppUser> _selectedReviewers = [];
  DateTime? _deadline;
  bool _isLoading = false;
  
  // PDF upload variables
  PlatformFile? _selectedPdf;
  bool _isUploadingPdf = false;
  bool _bucketExists = false;

  @override
  void initState() {
    super.initState();
    _loadReviewers();
    _checkBucketExists();
  }

  Future<void> _checkBucketExists() async {
    final exists = await PDFUploadService.checkBucketExists();
    setState(() {
      _bucketExists = exists;
    });
    if (!exists) {
      debugPrint('⚠️ PDF upload disabled: Storage bucket not found');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewers() async {
    try {
      final reviewers = await _adminService.getAvailableReviewers();
      setState(() {
        _availableReviewers = reviewers;
      });
    } catch (e) {
      debugPrint('❌ Failed to load reviewers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reviewers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select deadline',
    );
    
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _submitNotesheet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedReviewers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one reviewer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser!;

      String? pdfUrl;
      String? pdfFileName;

      // Upload PDF if selected
      if (_selectedPdf != null) {
        debugPrint('📄 Uploading PDF: ${_selectedPdf!.name}');
        
        if (kIsWeb && _selectedPdf!.bytes != null) {
          // Web platform - upload from bytes
          pdfUrl = await PDFUploadService.uploadPDFFromBytes(
            fileBytes: _selectedPdf!.bytes!,
            fileName: _selectedPdf!.name,
            userId: currentUser.uid,
          );
        } else if (!kIsWeb && _selectedPdf!.path != null) {
          // Mobile platform - upload from file path
          pdfUrl = await PDFUploadService.uploadPDF(
            filePath: _selectedPdf!.path!,
            fileName: _selectedPdf!.name,
            userId: currentUser.uid,
          );
        }
        
        pdfFileName = _selectedPdf!.name;
        debugPrint('✅ PDF uploaded successfully: $pdfUrl');
      }

      final notesheetId = await _databaseService.createNotesheet(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorUid: currentUser.uid,
        creatorName: currentUser.name,
        reviewers: _selectedReviewers,
        deadline: _deadline,
        pdfUrl: pdfUrl,
        pdfFileName: pdfFileName,
      );

      debugPrint('✅ Notesheet created successfully: $notesheetId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notesheet created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('❌ Failed to create notesheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create notesheet: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectPdf() async {
    try {
      setState(() {
        _isUploadingPdf = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb, // Load data for web platform
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedPdf = file;
        });

        debugPrint('✅ PDF selected: ${file.name} (${file.size} bytes)');
      }
    } catch (e) {
      debugPrint('❌ Failed to select PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPdf = false;
        });
      }
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Notesheet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Enter notesheet title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.trim().length < 3) {
                          return 'Title must be at least 3 characters long';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Enter detailed description of the request',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters long';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Deadline field
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Deadline'),
                        subtitle: _deadline != null
                            ? Text(
                                '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : const Text('Optional - Select a deadline'),
                        trailing: _deadline != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _deadline = null;
                                  });
                                },
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: _selectDeadline,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // PDF Upload Section
                    Text(
                      'Attach PDF Document',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (!_bucketExists)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'PDF upload is currently unavailable. Please ask your administrator to set up the storage bucket.',
                                  style: TextStyle(color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        child: _selectedPdf == null
                            ? ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                title: const Text('Select PDF Document'),
                                subtitle: const Text('Optional - Upload supporting document (Max 10MB)'),
                                trailing: _isUploadingPdf
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.upload_file),
                                onTap: _isUploadingPdf ? null : _selectPdf,
                              )
                            : ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                title: Text(_selectedPdf!.name),
                                subtitle: Text('${(_selectedPdf!.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: _removePdf,
                                      tooltip: 'Remove PDF',
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Reviewers section
                    Text(
                      'Select Reviewers *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_availableReviewers.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('No reviewers available. Please contact your administrator.'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._availableReviewers.map((reviewer) {
                        final isSelected = _selectedReviewers.contains(reviewer);
                        return Card(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: CheckboxListTile(
                            title: Text(reviewer.name),
                            subtitle: Text('${reviewer.department} • ${reviewer.role!.displayName}'),
                            secondary: CircleAvatar(
                              backgroundColor: reviewer.isAdmin 
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                reviewer.isAdmin ? Icons.admin_panel_settings : Icons.rate_review,
                                color: reviewer.isAdmin ? Colors.red : Colors.blue,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedReviewers.add(reviewer);
                                } else {
                                  _selectedReviewers.remove(reviewer);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    
                    if (_selectedReviewers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Review Order',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'The notesheet will be reviewed in the order you selected:',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(_selectedReviewers.length, (index) {
                                final reviewer = _selectedReviewers[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          reviewer.name,
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // PDF Upload section
                    Text(
                      'Upload Supporting PDF (optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf),
                        title: const Text('Select PDF'),
                        subtitle: _selectedPdf != null
                            ? Text(
                                _selectedPdf!.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : const Text('Optional - Attach a PDF file'),
                        trailing: _selectedPdf != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _removePdf,
                              )
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: _selectPdf,
                      ),
                    ),
                    
                    if (_isUploadingPdf) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _availableReviewers.isNotEmpty ? _submitNotesheet : null,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Notesheet'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
