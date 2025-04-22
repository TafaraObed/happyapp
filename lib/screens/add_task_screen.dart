import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/course.dart'; // To select associated course

class AddTaskScreen extends StatefulWidget {
  final Task? initialTask; // Optional for editing
  final List<Course> courses; // Needed for course dropdown

  const AddTaskScreen({
    super.key,
    this.initialTask,
    required this.courses,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  String? _selectedCourseId;
  DateTime? _selectedDueDate;

  late String _appBarTitle;
  late String _saveButtonText;
  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.initialTask!;
      _titleController.text = task.title;
      _selectedCourseId = task.courseId;
      _selectedDueDate = task.dueDate;
      _appBarTitle = 'Edit Task';
      _saveButtonText = 'Update Task';
    } else {
      _appBarTitle = 'Add New Task';
      _saveButtonText = 'Save Task';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // --- Date Picker Logic ---
  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDueDate) {
      setState(() {
        _selectedDueDate = pickedDate;
      });
    }
  }

  // --- Save Logic ---
  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final taskData = Task(
        id: _isEditing ? widget.initialTask!.id : null, // Let constructor generate if new
        title: _titleController.text,
        courseId: _selectedCourseId,
        dueDate: _selectedDueDate,
        // Retain completion status if editing, otherwise default (false)
        isComplete: _isEditing ? widget.initialTask!.isComplete : false, 
      );
      Navigator.of(context).pop(taskData); // Return new/updated task
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: _saveButtonText,
            onPressed: _saveTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title for the task.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Course Selection Dropdown
              DropdownButtonFormField<String?>(
                 value: _selectedCourseId,
                 hint: const Text('Link to Course (Optional)'),
                 decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.book_outlined),
                 ),
                 // Allow clearing selection
                 isExpanded: true,
                 items: [
                    const DropdownMenuItem<String?>(
                      value: null, // Represent no selection
                      child: Text('None'),
                    ),
                   ...widget.courses.map((course) {
                     return DropdownMenuItem<String?>(
                       value: course.id,
                       child: Text(course.name, overflow: TextOverflow.ellipsis),
                     );
                   }).toList(),
                 ],
                 onChanged: (String? newValue) {
                   setState(() {
                     _selectedCourseId = newValue;
                   });
                 },
              ),
               const SizedBox(height: 16.0),
              // Due Date Picker
               Row(
                 children: [
                   Expanded(
                     child: Text(
                       _selectedDueDate == null 
                         ? 'No Due Date Set' 
                         : 'Due: ${DateFormat.yMd().format(_selectedDueDate!)}',
                       style: Theme.of(context).textTheme.titleMedium,
                     ),
                   ),
                   TextButton.icon(
                     icon: const Icon(Icons.calendar_today),
                     label: Text(_selectedDueDate == null ? 'Set Date' : 'Change Date'),
                     onPressed: _pickDueDate,
                   ),
                 ],
               ),
              const SizedBox(height: 32.0),
              // Save Button (alternative placement)
              ElevatedButton.icon(
                 icon: const Icon(Icons.save),
                 label: Text(_saveButtonText),
                 onPressed: _saveTask,
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