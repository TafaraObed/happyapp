import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/course.dart';
import '../models/program.dart';
import '../services/predefined_courses_service.dart';
import '../widgets/tap_scale_container.dart';

class PredefinedCoursesScreen extends StatefulWidget {
  const PredefinedCoursesScreen({super.key});

  @override
  State<PredefinedCoursesScreen> createState() => _PredefinedCoursesScreenState();
}

class _PredefinedCoursesScreenState extends State<PredefinedCoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Program> _programs = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }
  
  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load all programs from the service
      final programs = PredefinedCoursesService.getAllPrograms();
      
      setState(() {
        _programs = programs;
        _tabController = TabController(length: programs.length, vsync: this);
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading predefined programs: $e");
      setState(() {
        _programs = [];
        _tabController = TabController(length: 1, vsync: this);
        _isLoading = false;
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading predefined courses')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Predefined Course'),
        elevation: 0,
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _programs.map((program) => Tab(text: program.name)).toList(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _programs.map((program) {
                return _ProgramCoursesTabView(
                  program: program,
                  onCourseSelected: (course) {
                    Navigator.of(context).pop(course);
                  },
                );
              }).toList(),
            ),
    );
  }
}

class _ProgramCoursesTabView extends StatelessWidget {
  final Program program;
  final Function(Course) onCourseSelected;

  const _ProgramCoursesTabView({
    required this.program,
    required this.onCourseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final courses = program.sampleCourses;
    
    return courses.isEmpty
        ? const Center(child: Text('No predefined courses available'))
        : ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              
              // Add program metadata to the course
              final courseWithMetadata = course.copyWith(
                metadata: {
                  'programId': program.id,
                  'programName': program.name,
                  'isPredefined': true,
                },
              );
              
              // Build subtitle with schedule and professor info
              final scheduleText = course.schedule
                  .map((entry) => entry.format(context))
                  .join(', ');
              
              final subtitle = [
                if (course.professor != null) course.professor!,
                if (scheduleText.isNotEmpty) scheduleText,
              ].join(' • ');
              
              return TapScaleContainer(
                onTap: () => onCourseSelected(courseWithMetadata),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: course.colorValue,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                course.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (course.room != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Room: ${course.room}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => onCourseSelected(courseWithMetadata),
                          child: const Text('Select Course'),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (100 * index).ms)
                .slideY(begin: 0.2, end: 0, duration: 300.ms, delay: (100 * index).ms);
            },
          );
  }
} 