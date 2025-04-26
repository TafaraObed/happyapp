import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for InputFormatters
import '../models/course.dart'; // Assuming models folder is one level up
import '../models/schedule_entry.dart'; // Import ScheduleEntry
import 'package:uuid/uuid.dart'; // For generating unique IDs

class AddCourseScreen extends StatefulWidget {
  final Course? initialCourse; // Optional course for editing

  const AddCourseScreen({super.key, this.initialCourse});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professorController = TextEditingController();
  final _roomController = TextEditingController();
  final _materialsLinkController = TextEditingController();
  final _notesLinkController = TextEditingController();
  final _manualGradeController = TextEditingController(); // Controller for manual grade
  late Color _selectedColor; // Keep this as Color for the picker UI
  late String _appBarTitle;
  late String _saveButtonText;
  bool get _isEditing => widget.initialCourse != null;

  // State for managing schedule entries
  late List<ScheduleEntry> _scheduleEntries;
  DayOfWeek? _selectedDay; // Temp state for adding new entry
  TimeOfDay? _selectedTime; // Temp state for adding new entry

  // Predefined colors for selection
  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // Populate fields if editing
      final course = widget.initialCourse!;
      _nameController.text = course.name;
      _professorController.text = course.professor ?? '';
      _roomController.text = course.room ?? '';
      // Convert hex string to Color
      _selectedColor = Color(int.parse(course.color, radix: 16) | 0xFF000000);
      _materialsLinkController.text = course.materialsLink ?? '';
      _notesLinkController.text = course.notesLink ?? '';
      _scheduleEntries = List<ScheduleEntry>.from(course.schedule); // Copy list
      // Initialize manual grade controller if editing and value exists
      if (course.manualGradePercent != null) {
        _manualGradeController.text = (course.manualGradePercent! * 100).toStringAsFixed(1);
      }
      _appBarTitle = 'Edit Course';
      _saveButtonText = 'Update Course';
    } else {
      // Default values for adding
      _selectedColor = Colors.blue; // Default Color object
      _appBarTitle = 'Add New Course';
      _saveButtonText = 'Save Course';
      _scheduleEntries = []; // Start with empty schedule list
      _materialsLinkController.text = '';
      _notesLinkController.text = '';
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _nameController.dispose();
    _professorController.dispose();
    _roomController.dispose();
    _materialsLinkController.dispose();
    _notesLinkController.dispose();
    _manualGradeController.dispose(); // Dispose the new controller
    super.dispose();
  }

  void _saveCourse() {
    // Basic validation: Ensure at least one schedule entry is added
    if (_scheduleEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one schedule entry.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Parse manual grade
      double? manualGradeValue;
      final gradeText = _manualGradeController.text.trim();
      if (gradeText.isNotEmpty) {
        final parsedGrade = double.tryParse(gradeText);
        // Basic check if parsing succeeded and within reasonable bounds (0-100)
        if (parsedGrade != null && parsedGrade >= 0 && parsedGrade <= 100) {
          manualGradeValue = parsedGrade / 100.0; // Store as 0.0 to 1.0
        } else {
          // If parsing fails or out of bounds, show error and stop saving
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Manual Grade must be a number between 0 and 100.')),
          );
          return; // Stop the save process
        }
      }

      final courseData = Course(
        id: _isEditing ? widget.initialCourse!.id : const Uuid().v4(),
        name: _nameController.text,
        professor: _professorController.text.isNotEmpty ? _professorController.text : null,
        room: _roomController.text.isNotEmpty ? _roomController.text : null,
        schedule: _scheduleEntries, // Use the list of ScheduleEntry objects
        // Convert Color value to hex string (remove alpha)
        color: _selectedColor.value.toRadixString(16).substring(2),
        materialsLink: _materialsLinkController.text.isNotEmpty ? _materialsLinkController.text : null,
        notesLink: _notesLinkController.text.isNotEmpty ? _notesLinkController.text : null,
        manualGradePercent: manualGradeValue, // Use the parsed value (or null)
      );

      // Pop the screen and return the new/updated course
      Navigator.of(context).pop(courseData);
    }
  }

  // --- Schedule Entry Management ---

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _addScheduleEntry() {
    if (_selectedDay != null && _selectedTime != null) {
      setState(() {
        _scheduleEntries.add(ScheduleEntry(day: _selectedDay!, time: _selectedTime!));
        // Reset selection for next entry
        _selectedDay = null;
        _selectedTime = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a day and a time.')),
      );
    }
  }

  void _removeScheduleEntry(int index) {
    setState(() {
      _scheduleEntries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle), // Dynamic title
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveCourse,
            tooltip: _saveButtonText, // Dynamic tooltip
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrollability if content overflows
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _professorController,
                decoration: const InputDecoration(
                  labelText: 'Professor (Optional)',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room (Optional)',
                  prefixIcon: Icon(Icons.room),
                ),
              ),
              const SizedBox(height: 16.0),
              Text('Schedule', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8.0),
              if (_scheduleEntries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: List.generate(_scheduleEntries.length, (index) {
                      final entry = _scheduleEntries[index];
                      return Chip(
                        label: Text(entry.format(context)),
                        onDeleted: () => _removeScheduleEntry(index),
                        deleteIconColor: Colors.redAccent,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                      );
                    }),
                  ),
                ),
              Card( // Wrap inputs in a card for visual grouping
                elevation: 0.5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<DayOfWeek>(
                              value: _selectedDay,
                              hint: const Text('Select Day'),
                              decoration: const InputDecoration(border: UnderlineInputBorder()),
                              items: DayOfWeek.values.map((DayOfWeek day) {
                                return DropdownMenuItem<DayOfWeek>(
                                  value: day,
                                  child: Text(dayOfWeekToString(day)),
                                );
                              }).toList(),
                              onChanged: (DayOfWeek? newValue) {
                                setState(() { _selectedDay = newValue; });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(_selectedTime?.format(context) ?? 'Select Time'),
                              onPressed: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Entry'),
                          onPressed: _addScheduleEntry,
                          style: ElevatedButton.styleFrom(
                            visualDensity: VisualDensity.compact, // Make button smaller
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _materialsLinkController,
                decoration: const InputDecoration(
                  labelText: 'Materials Link (Optional)',
                  hintText: 'e.g., https://drive.google.com/...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesLinkController,
                decoration: const InputDecoration(
                  labelText: 'Notes Link (Optional)',
                  hintText: 'e.g., https://notion.so/...',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16.0),
              // --- Manual Grade Field ---
              TextFormField(
                controller: _manualGradeController,
                decoration: const InputDecoration(
                  labelText: 'Manual Grade (%)',
                  hintText: 'e.g., 87.5',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Allow numbers, optional decimal point, and one decimal place
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,1})?$')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Optional field
                  }
                  final number = double.tryParse(value);
                  if (number == null) {
                    return 'Please enter a valid number';
                  }
                  if (number < 0 || number > 100) {
                    return 'Grade must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              Text('Select Course Color:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8.0),
              Wrap( // Use Wrap for the color circles
                spacing: 10.0,
                runSpacing: 10.0,
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color; // Still setting the Color object
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: color, // Still using the Color object for display
                      child: _selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
               const SizedBox(height: 32.0),
               ElevatedButton.icon(
                 icon: const Icon(Icons.save),
                 label: Text(_saveButtonText), // Dynamic button text
                 onPressed: _saveCourse,
                 style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16),
                 ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 