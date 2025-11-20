// lib/widgets/event_submission_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notesheet.dart';
import '../services/notesheet_service.dart';
import '../utils/locator.dart';
import '../utils/enums.dart'; // Make sure you import your enums if NotesheetStatus is defined there

class EventSubmissionForm extends StatefulWidget {
  const EventSubmissionForm({super.key});

  @override
  State<EventSubmissionForm> createState() => _EventSubmissionFormState();
}

class _EventSubmissionFormState extends State<EventSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _organizerNameController =
      TextEditingController();
  final TextEditingController _organizerContactController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();
  final TextEditingController _otherResourcesController =
      TextEditingController();
  final TextEditingController _audienceSizeController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _modeOfEvent;
  String? _typeOfEvent;
  String? _audienceType;
  String? _fundSource;
  bool _agreedToTerms = false;

  List<String> selectedResources = [];
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

  // Get the NotesheetService instance
  final NotesheetService _notesheetService = locator<NotesheetService>();

  @override
  void dispose() {
    _eventTitleController.dispose();
    _organizerNameController.dispose();
    _organizerContactController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _budgetController.dispose();
    _additionalNotesController.dispose();
    _otherResourcesController.dispose();
    _audienceSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      initialTime: TimeOfDay.now(),
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
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      // Validate all required date/time and dropdowns explicitly
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the Date of Event.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_startTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the Start Time.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the End Time.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_modeOfEvent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the Mode of Event.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_typeOfEvent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the Type of Event.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_audienceType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the Audience Type.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_fundSource == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the Fund Source.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Combine date and time into a single DateTime object for start and end
      // Use the selected date with the time from the time pickers
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

      // Get current user ID
      final String? proposerId = FirebaseAuth.instance.currentUser?.uid;

      if (proposerId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to propose an event.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Concatenate selected resources into a single string
      String combinedResources = selectedResources.join(', ');
      if (_otherResourcesController.text.isNotEmpty) {
        if (combinedResources.isNotEmpty) {
          combinedResources += ', ';
        }
        combinedResources += _otherResourcesController.text.trim();
      }

      try {
        final now = DateTime.now(); // For createdAt and lastStatusChangeAt

        final newNotesheet = Notesheet(
          id: null, // Firestore will generate this
          proposerId: proposerId,
          title: _eventTitleController.text.trim(),
          organizerName: _organizerNameController.text.trim(),
          dateOfEvent: _selectedDate!, // Pass the selected date
          startTime: startDateTime, // Combined DateTime
          endTime: endDateTime, // Combined DateTime
          modeOfEvent: _modeOfEvent!,
          typeOfEvent: _typeOfEvent!,
          description: _descriptionController.text.trim(),
          venue: _venueController.text.trim(),
          audienceSize: int.tryParse(_audienceSizeController.text.trim()) ?? 0,
          audienceType: _audienceType!,
          estimatedBudget:
              double.tryParse(_budgetController.text.trim()) ?? 0.0,
          fundSource: _fundSource!,
          resourcesRequested: combinedResources, // Pass the combined string
          additionalNote: _additionalNotesController.text
              .trim(), // Correct field name
          status: NotesheetStatus.underConsideration, // Default status
          approvalCount: 0, // Default approval count
          approvedBy: const [], // Default empty list
          // hodSuggestedChangesNotesheetId and originalNotesheetId are nullable and not set on initial proposal
          createdAt: now, // Set creation timestamp
          lastStatusChangeAt: now, // Set initial status change timestamp
        );

        await _notesheetService.proposeNotesheet(newNotesheet);

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Event submitted successfully for approval!'),
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
      } catch (e) {
        print('Error submitting event: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _eventTitleController.clear();
      _organizerNameController.clear();
      _organizerContactController.clear();
      _descriptionController.clear();
      _venueController.clear();
      _budgetController.clear();
      _additionalNotesController.clear();
      _otherResourcesController.clear();
      _audienceSizeController.clear();
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _modeOfEvent = null;
      _typeOfEvent = null;
      _audienceType = null;
      _fundSource = null;
      selectedResources.clear();
      _agreedToTerms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🟦 Basic Event Info Section
          _buildSectionHeader('🧾 Basic Event Info'),
          _buildTextField(
            controller: _eventTitleController,
            label: 'Event Title',
            hint: 'e.g., Coding Bootcamp 2025',
            validator: (value) => value!.isEmpty ? 'Required field' : null,
          ),
          _buildTextField(
            controller: _organizerNameController,
            label: 'Organizer Name',
            hint: 'Name of person/team requesting the event',
            validator: (value) => value!.isEmpty ? 'Required field' : null,
          ),
          _buildTextField(
            controller: _organizerContactController,
            label: 'Organizer Contact Info',
            hint: 'Email or phone number for contact',
            validator: (value) => value!.isEmpty ? 'Required field' : null,
            keyboardType: TextInputType.emailAddress,
          ),
          // Date and Time Pickers
          Row(
            children: [
              Expanded(
                child: _buildDatePickerField(
                  label: 'Date of Event',
                  selectedDate: _selectedDate,
                  onTap: () => _selectDate(context),
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerField(
                  label: 'Start Time',
                  selectedTime: _startTime,
                  onTap: () => _selectStartTime(context),
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerField(
                  label: 'End Time',
                  selectedTime: _endTime,
                  onTap: () => _selectEndTime(context),
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mode and Type Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Mode of Event',
                  value: _modeOfEvent,
                  items: modeOptions,
                  onChanged: (value) {
                    setState(() {
                      _modeOfEvent = value;
                    });
                  },
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Type of Event',
                  value: _typeOfEvent,
                  items: typeOptions,
                  onChanged: (value) {
                    setState(() {
                      _typeOfEvent = value;
                    });
                  },
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description / Objective',
            hint: 'What the event is about and why it\'s important',
            maxLines: 4,
            validator: (value) => value!.isEmpty ? 'Required field' : null,
          ),

          // 🏛️ Venue & Logistics Section
          _buildSectionHeader('🏛️ Venue & Logistics'),
          _buildTextField(
            controller: _venueController,
            label: 'Proposed Venue / Platform',
            hint:
                'Physical venue or virtual platform (e.g., "Auditorium", "Google Meet")',
            validator: (value) => value!.isEmpty ? 'Required field' : null,
          ),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _audienceSizeController,
                  label: 'Expected Audience Size',
                  hint: 'Estimated number of participants',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required field';
                    if (int.tryParse(value) == null) return 'Enter a number';
                    if (int.parse(value) <= 0) return 'Must be positive';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Audience Type',
                  value: _audienceType,
                  items: audienceOptions,
                  onChanged: (value) {
                    setState(() {
                      _audienceType = value;
                    });
                  },
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
            ],
          ),

          // 💸 Funding & Resources Section
          _buildSectionHeader('💸 Funding & Resources'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _budgetController,
                  label: 'Estimated Budget',
                  hint: 'Total funds required',
                  prefixText: '\₹ ', // Changed to Rupee symbol
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Required field';
                    if (double.tryParse(value) == null) return 'Enter a number';
                    if (double.parse(value) < 0) return 'Cannot be negative';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Fund Source',
                  value: _fundSource,
                  items: fundSourceOptions,
                  onChanged: (value) {
                    setState(() {
                      _fundSource = value;
                    });
                  },
                  validator: (value) => value == null ? 'Required field' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Resources Requested',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          // Resources Checklist
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resourceOptions.map((resource) {
              return FilterChip(
                label: Text(resource),
                selected: selectedResources.contains(resource),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedResources.add(resource);
                    } else {
                      selectedResources.remove(resource);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _otherResourcesController,
            label: 'Other Resources',
            hint: 'Specify any other resources needed',
          ),

          // 📝 Additional Notes Section
          _buildSectionHeader('📝 Additional Notes'),
          _buildTextField(
            controller: _additionalNotesController,
            hint:
                'Any specific requirements, collaborations, or risk mitigation notes',
            maxLines: 3,
          ),

          // ✅ Declaration Section
          _buildSectionHeader('✅ Declaration'),
          const Text(
            'I declare that the above information is true and that I take full responsibility for the conduct of the event. I understand the event will only be held after all approvals are received.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (bool? value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
              ),
              const Text('I Agree'),
            ],
          ),

          // Submit Button
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit for Approval',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          prefixText: prefixText,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    String? Function(DateTime?)? validator,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
          errorText: (validator != null && selectedDate == null)
              ? validator(selectedDate)
              : null,
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('MMM dd, yyyy').format(selectedDate)
              : 'Select date',
        ),
      ),
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TimeOfDay? selectedTime,
    required VoidCallback onTap,
    String? Function(TimeOfDay?)? validator,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
          errorText: (validator != null && selectedTime == null)
              ? validator(selectedTime)
              : null,
        ),
        child: Text(
          selectedTime != null ? selectedTime.format(context) : 'Select time',
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
