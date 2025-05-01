import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // For RichText Taps
import 'signup_screen.dart'; // To navigate to signup
import '../helpers/database_helper.dart'; // For login logic
import '../models/user.dart'; // For User model
import 'package:provider/provider.dart'; // To manage login state potentially
import '../main.dart' show MainScreen; // Import MainScreen from main.dart
import 'package:flutter/cupertino.dart'; // For iOS-style transitions
import '../providers/auth_provider.dart'; // <<< Import AuthProvider

class LoginScreen extends StatefulWidget {
  final String? prefillUsername; // Optional username from signup

  const LoginScreen({super.key, this.prefillUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefillUsername != null) {
      _usernameController.text = widget.prefillUsername!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check for route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('prefillUsername')) {
      final username = args['prefillUsername'] as String;
      if (username.isNotEmpty) {
        _usernameController.text = username;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final username = _usernameController.text;
      final password = _passwordController.text;
      final authProvider = Provider.of<AuthProvider>(context, listen: false); // Get AuthProvider

      // --- IMPORTANT: Hashing --- 
      // In a real app, you would hash the password entered by the user
      // using the same algorithm and salt (if applicable) used during signup
      // before comparing it with the stored hash.
      // For this example, we are comparing plain text (NOT SECURE).
      // Example using a hypothetical hashing function:
      // String hashedPassword = await hashPassword(password); 
      // final User? user = await _dbHelper.login(username, hashedPassword);
      // --- End Hashing Note ---

      final User? user = await _dbHelper.login(username, password);

      setState(() { _isLoading = false; });

      if (user != null) {
        // Successful login
        // Update AuthProvider state (now using async method)
        await authProvider.login(user);

        // Explicitly navigate to MainScreen after successful login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else {
        // Failed login
        setState(() {
          _errorMessage = 'Invalid username or password';
        });
      }
    }
  }

  void _navigateToSignUp() {
     Navigator.of(context).push(
       CupertinoPageRoute(builder: (context) => const SignupScreen()),
     );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // Use a subtle background gradient or color
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Container( // Wrap with Container for potential background
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage( // Select image based on brightness
              isDarkMode
                ? 'assets/images/study_background.jpg' // Dark theme image
                : 'assets/images/study_light_background.jpg', // Light theme image
            ),
            fit: BoxFit.cover, // Cover the entire screen
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400), // Limit width on larger screens
              child: Card(
                elevation: 0,
                // Mimic the glassmorphism/frosted glass effect with transparency
                color: theme.colorScheme.surface.withOpacity(0.85), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Name / Title Area
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Study Planner by Tafara', 
                              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            TextButton(
                              onPressed: _navigateToSignUp,
                              child: Text(
                                'Sign up',
                                 style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                               ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32.0),

                        // Log In Title
                        Text(
                          'Log in', 
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
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
                              return 'Please enter your username';
                            }
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
                            suffixIcon: Row(
                               mainAxisSize: MainAxisSize.min, // Prevent row from taking full width
                               mainAxisAlignment: MainAxisAlignment.end, // Align items to the end
                               children: [
                                // Toggle Password Visibility
                                 IconButton(
                                   icon: Icon(
                                     _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                   ),
                                   onPressed: () {
                                     setState(() {
                                       _obscurePassword = !_obscurePassword;
                                     });
                                   },
                                 ),
                                // Forgot Password (Placeholder)
                                 Padding(
                                   padding: const EdgeInsets.only(right: 8.0), // Add some padding
                                   child: TextButton(
                                      onPressed: () {
                                        // TODO: Implement Forgot Password
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Forgot Password functionality not implemented yet.')),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        textStyle: theme.textTheme.bodySmall,
                                      ),
                                      child: const Text('I forgot'),
                                    ),
                                 ),
                               ],
                             )
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _isLoading ? null : _login(), // Allow login on Enter
                        ),
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

                        const SizedBox(height: 24.0),

                        // Login Button
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(16.0),
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                ),
                                child: const Icon(Icons.arrow_forward),
                              ),
                        
                         const SizedBox(height: 16.0), // Spacer at the bottom

                        // --- Social Login (Optional - Omitted based on design) ---
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     // ... Facebook/Google buttons ...
                        //   ],
                        // ),

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
} 