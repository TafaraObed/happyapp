import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/user.dart';
// To navigate back after signup
// For iOS-style transitions
import '../models/program.dart'; // Import Program model

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _selectedProgramId;
  List<Program> _programs = [];
  bool _loadingPrograms = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _loadingPrograms = true;
      _errorMessage = null; // Clear any previous errors
    });
    
    try {
      print("SignupScreen: Attempting to load programs...");
      final programs = await _dbHelper.getPrograms();
      print("SignupScreen: Received ${programs.length} programs from database");
      
      if (programs.isEmpty) {
        print("SignupScreen: WARNING - No programs returned from database");
        setState(() {
          _loadingPrograms = false;
          _errorMessage = 'Unable to load study programs. Please try again later.';
        });
        return;
      }
      
      setState(() {
        _programs = programs;
        _loadingPrograms = false;
        // Select the first program by default if available
        if (programs.isNotEmpty) {
          _selectedProgramId = programs.first.id;
          print("SignupScreen: Selected program: ${programs.first.name} (${programs.first.id})");
        }
      });
    } catch (e) {
      print("SignupScreen: ERROR loading programs: $e");
      setState(() {
        _loadingPrograms = false;
        _errorMessage = 'Failed to load study programs. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    setState(() {
      _errorMessage = null; // Clear previous error on new attempt
    });
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      final username = _usernameController.text;
      final password = _passwordController.text;

      // Check if username already exists
      bool exists = await _dbHelper.checkUsernameExists(username);
      if (exists) {
         setState(() {
           _isLoading = false;
           _errorMessage = 'Username already taken. Please choose another.';
         });
         return; // Stop signup process
      }

      // --- IMPORTANT: Hashing ---
      // In a real app, hash the password here before storing.
      // Use a strong, salted hashing algorithm (e.g., bcrypt, Argon2).
      // String hashedPassword = await hashPassword(password);
      // final newUser = User(username: username, password: hashedPassword, programId: _selectedProgramId);
      // --- End Hashing Note ---
      
      final newUser = User(
        username: username, 
        password: password, // Storing plain text (NOT SECURE)
        programId: _selectedProgramId,
      );

      final result = await _dbHelper.signUp(newUser);

      if (result > 0) {
        // Get the user with ID to add sample courses and tasks
        final User? createdUser = await _dbHelper.login(username, password);
        
        if (createdUser != null && createdUser.programId != null) {
          // Add sample courses first
          await _dbHelper.addSampleCoursesForUser(createdUser.id!, createdUser.programId!);
          
          // Get the courses that were just added to link tasks to them
          final userCourses = await _dbHelper.getCourses(createdUser.id!);
          
          // Add sample tasks linked to the courses
          await _dbHelper.addSampleTasksForUser(createdUser.id!, createdUser.programId!, userCourses);
        }
        
        setState(() { _isLoading = false; });
        
        // Successful signup
        if (mounted) { // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful! Please log in.'), duration: Duration(seconds: 2)),
          );
          // Navigate back to login, pre-filling the username
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (Route<dynamic> route) => false, // Remove all routes below
            arguments: {'prefillUsername': username}, // Pass username as arguments
          );
        }
      } else if (result == -1) {
         setState(() {
           _isLoading = false;
           _errorMessage = 'Username already taken. Please choose another.';
         });
      } else {
        // Other database error
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred during signup. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Slightly different background for visual distinction?
    final Color baseBackgroundColor = Color.alphaBlend(
       theme.colorScheme.primary.withOpacity(isDarkMode ? 0.03 : 0.05), // Adjust opacity based on theme
       theme.colorScheme.surfaceContainerLowest,
    );

    return Scaffold(
      backgroundColor: baseBackgroundColor, // Use the blended color or just surfaceContainerLowest
      appBar: AppBar(
        title: const Text('Sign Up'),
        elevation: 0,
        backgroundColor: Colors.transparent, // Make AppBar transparent
        foregroundColor: theme.colorScheme.onSurface, // Ensure icons/text are visible
      ),
      body: Container( // Wrap with Container for potential background
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage( // Select image based on brightness
              isDarkMode
                ? 'assets/images/study_background.jpg' // Dark theme image
                : 'assets/images/study_light_background.jpg', // Light theme image
            ),
            fit: BoxFit.cover, // Cover the entire screen
            // Apply color filter only for dark mode image
            colorFilter: isDarkMode
              ? const ColorFilter.mode(
                  Colors.black45, // Semi-transparent black overlay
                  BlendMode.darken, // Blend mode
                )
              : null, // No filter for light mode image
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400), // Limit width
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surface.withOpacity(0.90), // Slightly more opaque?
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account', 
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24.0),

                        // Username Field
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline),
                            labelText: 'Username',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) { // Example validation
                              return 'Username must be at least 3 characters';
                            }
                            // Add more validation if needed (e.g., no spaces)
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16.0),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            labelText: 'Password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) { // Example validation
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16.0),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                             prefixIcon: const Icon(Icons.lock_outline),
                             labelText: 'Confirm Password',
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
                             filled: true,
                             fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                             suffixIcon: IconButton(
                               icon: Icon(
                                 _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                               ),
                               onPressed: () {
                                 setState(() {
                                   _obscureConfirmPassword = !_obscureConfirmPassword;
                                 });
                               },
                             ),
                           ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next, // Changed to next for program selection
                        ),
                        const SizedBox(height: 16.0),
                        
                        // Program Selection Dropdown
                        _buildProgramSelector(),
                        
                        const SizedBox(height: 8.0),

                        // Error Message Display
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                        const SizedBox(height: 32.0),

                        // Signup Button
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                                ),
                                child: const Text('Create Account'),
                              ),
                        
                        const SizedBox(height: 16.0),
                        
                        // Back to Login Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Already have an account? Log in'),
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
      ),
    );
  }

  // Fallback program selection UI if loading fails
  Widget _buildProgramSelector() {
    if (_loadingPrograms) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_programs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              'Study Program',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded, 
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unable to load programs. Please restart the app or try again later.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                TextButton(
                  onPressed: _loadPrograms,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.school_outlined),
        labelText: 'Study Program',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a program';
        }
        return null;
      },
      value: _selectedProgramId,
      items: _programs.map((Program program) {
        return DropdownMenuItem<String>(
          value: program.id,
          child: Text(program.name),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedProgramId = newValue;
        });
      },
    );
  }
} 