// lib/widgets/suggest_edit_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../models/notesheet.dart'; // Import Notesheet model
import '../../services/notesheet_service.dart'; // Import NotesheetService
import '../../utils/locator.dart'; // Import locator

class SuggestEditFormDialog extends StatefulWidget {
  final Notesheet initialNotesheet; // Changed type to Notesheet object

  const SuggestEditFormDialog({super.key, required this.initialNotesheet});

  @override
  State<SuggestEditFormDialog> createState() => _SuggestEditFormDialogState();
}

class _SuggestEditFormDialogState extends State<SuggestEditFormDialog> {
  final NotesheetService _notesheetService = locator<NotesheetService>();

  late TextEditingController titleController;
  late TextEditingController organizerNameController;
  // Removed: late TextEditingController organizerContactController;
  late TextEditingController descriptionController;
  late TextEditingController venueController;
  late TextEditingController audienceSizeController;
  late TextEditingController budgetController;
  late TextEditingController otherResourcesController;
  late TextEditingController additionalNoteController;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _modeOfEvent;
  String? _typeOfEvent;
  String? _audienceType;
  String? _fundSource;
  List<String> _selectedResources = [];

  final List<String> resourceOptions = [
    'Projector',
    'Mic/Speakers',
    'Food/Refreshments',
    'Certificates',
    'Stationery',
    'Volunteers',
  ];
  final List<String> modeOptions = ['Offline', 'Online', 'Hybrid'];
  final List<String> typeOptions = [
    'Workshop',
    'Seminar',
    'Competition',
    'Cultural',
    'Sports',
    'Other',
  ];
  final List<String> audienceOptions = ['Internal', 'External', 'Both'];
  final List<String> fundSourceOptions = [
    'College',
    'Sponsor',
    'Club Budget',
    'Self-Funded',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from initialNotesheet
    titleController = TextEditingController(
      text: widget.initialNotesheet.title,
    );
    organizerNameController = TextEditingController(
      text: widget.initialNotesheet.organizerName,
    );
    // Removed: organizerContactController = TextEditingController(text: widget.initialNotesheet.organizerContact);
    descriptionController = TextEditingController(
      text: widget.initialNotesheet.description,
    );
    venueController = TextEditingController(
      text: widget.initialNotesheet.venue,
    );
    audienceSizeController = TextEditingController(
      text: widget.initialNotesheet.audienceSize.toString(),
    );
    budgetController = TextEditingController(
      text: widget.initialNotesheet.estimatedBudget.toString(),
    );
    additionalNoteController = TextEditingController(
      text: widget.initialNotesheet.additionalNote,
    );

    // For resourcesRequested, split the string back into a list if it was joined
    _selectedResources = widget.initialNotesheet.resourcesRequested
        .split(', ')
        .where((e) => resourceOptions.contains(e))
        .toList();
    // Handle 'otherResources' if it's part of the combined string
    final otherResourcesPart = widget.initialNotesheet.resourcesRequested
        .split(', ')
        .where((e) => !resourceOptions.contains(e))
        .join(', ');
    otherResourcesController = TextEditingController(text: otherResourcesPart);

    _selectedDate = widget.initialNotesheet.dateOfEvent;
    _startTime = TimeOfDay.fromDateTime(widget.initialNotesheet.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.initialNotesheet.endTime);
    _modeOfEvent = widget.initialNotesheet.modeOfEvent;
    _typeOfEvent = widget.initialNotesheet.typeOfEvent;
    _audienceType = widget.initialNotesheet.audienceType;
    _fundSource = widget.initialNotesheet.fundSource;
  }

  @override
  void dispose() {
    titleController.dispose();
    organizerNameController.dispose();
    // Removed: organizerContactController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    audienceSizeController.dispose();
    budgetController.dispose();
    otherResourcesController.dispose();
    additionalNoteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _submitSuggestion() async {
    // Validate required fields before submitting
    if (!mounted) return; // Ensure widget is still mounted
    if (_selectedDate == null ||
        _startTime == null ||
        _endTime == null ||
        _modeOfEvent == null ||
        _typeOfEvent == null ||
        _audienceType == null ||
        _fundSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final DateTime endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    String combinedResources = _selectedResources.join(', ');
    if (otherResourcesController.text.isNotEmpty) {
      if (combinedResources.isNotEmpty) {
        combinedResources += ', ';
      }
      combinedResources += otherResourcesController.text.trim();
    }

    final Notesheet modifiedNotesheetData = widget.initialNotesheet.copyWith(
      title: titleController.text.trim(),
      organizerName: organizerNameController.text.trim(),
      // Removed: organizerContact: organizerContactController.text.trim(),
      description: descriptionController.text.trim(),
      venue: venueController.text.trim(),
      dateOfEvent: _selectedDate!,
      startTime: startDateTime,
      endTime: endDateTime,
      modeOfEvent: _modeOfEvent!,
      typeOfEvent: _typeOfEvent!,
      audienceSize: int.tryParse(audienceSizeController.text.trim()) ?? 0,
      audienceType: _audienceType!,
      estimatedBudget: double.tryParse(budgetController.text.trim()) ?? 0.0,
      fundSource: _fundSource!,
      resourcesRequested: combinedResources,
      additionalNote: additionalNoteController.text.trim(),
      // Status, approvalCount, approvedBy, createdAt, lastStatusChangeAt
      // will be handled by the service's suggestChanges method for the sudo notesheet.
      // We are essentially creating a new Notesheet object with the HOD's suggested changes.
    );

    try {
      await _notesheetService.suggestChanges(
        widget.initialNotesheet.id!, // Original notesheet ID
        modifiedNotesheetData, // The new Notesheet object with HOD's edits
      );
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Suggestions submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit suggestions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Suggest Edits'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: organizerNameController,
              decoration: const InputDecoration(
                labelText: 'Organizer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Removed: TextField for organizerContactController
            // Date and Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Event',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Select date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _startTime != null
                            ? _startTime!.format(context)
                            : 'Select time',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : 'Select time',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mode and Type Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Mode of Event',
                      border: OutlineInputBorder(),
                    ),
                    value: _modeOfEvent,
                    items: modeOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _modeOfEvent = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type of Event',
                      border: OutlineInputBorder(),
                    ),
                    value: _typeOfEvent,
                    items: typeOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _typeOfEvent = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: venueController,
              decoration: const InputDecoration(
                labelText: 'Venue',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: audienceSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Audience Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Audience Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _audienceType,
                    items: audienceOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _audienceType = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: budgetController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Budget',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Fund Source',
                      border: OutlineInputBorder(),
                    ),
                    value: _fundSource,
                    items: fundSourceOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fundSource = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Resources Requested',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: resourceOptions.map((resource) {
                return FilterChip(
                  label: Text(resource),
                  selected: _selectedResources.contains(resource),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedResources.add(resource);
                      } else {
                        _selectedResources.remove(resource);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: otherResourcesController,
              decoration: const InputDecoration(
                labelText: 'Other Resources',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: additionalNoteController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitSuggestion,
          child: const Text('Submit Suggestion'),
        ),
      ],
    );
  }
}
