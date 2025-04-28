import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/course.dart'; // To select associated course
import 'package:flutter/services.dart'; // For input formatters
import 'package:provider/provider.dart'; // Add provider import
import '../providers/tasks_provider.dart'; // Add tasks provider import

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
  final _pointsEarnedController = TextEditingController();
  final _pointsPossibleController = TextEditingController();
  
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
      _pointsEarnedController.text = task.pointsEarned?.toString() ?? '';
      _pointsPossibleController.text = task.pointsPossible?.toString() ?? '';
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
    _pointsEarnedController.dispose();
    _pointsPossibleController.dispose();
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

  // --- Save Logic (Updated to use Provider) ---
  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final double? pointsEarned = double.tryParse(_pointsEarnedController.text);
      final double? pointsPossible = double.tryParse(_pointsPossibleController.text);

      if (pointsEarned != null && (pointsPossible == null || pointsPossible <= 0)) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('If Points Earned are entered, Points Possible must be a positive number.')),
         );
         return;
      }
      if (pointsEarned != null && pointsPossible != null && pointsEarned > pointsPossible) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Points Earned cannot exceed Points Possible.')),
         );
         return;
      }

      final taskData = Task(
        id: _isEditing ? widget.initialTask!.id : null, // Provider handles null ID
        title: _titleController.text,
        courseId: _selectedCourseId,
        dueDate: _selectedDueDate,
        isComplete: _isEditing ? widget.initialTask!.isComplete : false,
        pointsEarned: pointsEarned,
        pointsPossible: pointsPossible,
        // Ensure timeLog is preserved when editing
        timeLog: _isEditing ? widget.initialTask!.timeLog : [],
      );
      
      // Get provider and call appropriate method
      final tasksProvider = Provider.of<TasksProvider>(context, listen: false);
      if (_isEditing) {
        tasksProvider.editTask(taskData);
      } else {
        tasksProvider.addTask(taskData);
      }

      // Pop the screen without returning data
      Navigator.of(context).pop();
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
              const SizedBox(height: 24.0),
              
              // --- Grade Inputs ---
              Text('Grade (Optional)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8.0),
              Row(
                 crossAxisAlignment: CrossAxisAlignment.start, // Align validators top
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _pointsEarnedController,
                       decoration: const InputDecoration(
                         labelText: 'Points Earned',
                         prefixIcon: Icon(Icons.star_half_outlined),
                       ),
                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                       inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+\.?[0-9]*')), // Allow digits and one dot
                       ],
                       // Basic validation - handled in _saveTask for dependency
                     ),
                   ),
                   const SizedBox(width: 16.0),
                    Expanded(
                     child: TextFormField(
                       controller: _pointsPossibleController,
                       decoration: const InputDecoration(
                         labelText: 'Points Possible',
                          prefixIcon: Icon(Icons.star_outline),
                       ),
                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                       inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+\.?[0-9]*')), 
                       ],
                      validator: (value) {
                         // Only validate if points earned is also filled
                         if (_pointsEarnedController.text.isNotEmpty && (value == null || value.isEmpty || double.tryParse(value) == 0)) {
                           return 'Req if earned pts entered';
                         }
                         if (value != null && value.isNotEmpty && (double.tryParse(value) ?? -1) < 0) {
                           return '>= 0';
                         }
                         return null;
                       },
                     ),
                   ),
                 ],
              ),
               // --- End Grade Inputs ---

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