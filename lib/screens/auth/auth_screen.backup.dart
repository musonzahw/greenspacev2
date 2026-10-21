import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Build social login button
  Widget _buildSocialButton({
    required String icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Image.asset(
              icon,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.error_outline,
                color: isDark ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Helper method to build text fields with consistent styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.green.shade400 : Colors.green.shade700,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPassword && label == 'Password' 
                        ? (_obscurePassword ? Icons.visibility_off : Icons.visibility)
                        : (_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                  onPressed: () {
                    setState(() {
                      if (label == 'Password') {
                        _obscurePassword = !_obscurePassword;
                      } else {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.green.shade400 : Colors.green.shade700,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        validator: validator,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();

    try {
      if (_isLogin) {
        final result = await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          if (result['success'] == true) {
            // Clear form fields
            _emailController.clear();
            _passwordController.clear();
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Signed in successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigate to home screen after a short delay
              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            }
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to sign in'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            
            // Log detailed error for debugging
            debugPrint('Sign-in Error: ${result['error']}');
            if (result['code'] != null) {
              debugPrint('Error Code: ${result['code']}');
            }
          }
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passwords do not match!'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        final result = await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          if (result['success'] == true) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Clear form and switch to login
            if (mounted) {
              _emailController.clear();
              _passwordController.clear();
              _confirmPasswordController.clear();
              setState(() => _isLogin = true);
            }
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'An error occurred'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            
            // Log detailed error for debugging
            debugPrint('Signup Error: ${result['error']}');
            if (result['code'] != null) {
              debugPrint('Error Code: ${result['code']}');
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        debugPrint('Auth Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Build the email field
    final emailField = _buildTextField(
      controller: _emailController,
      label: 'Email',
      icon: Icons.email_rounded,
      isDark: isDark,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
    
    // Build the password field
    final passwordField = _buildTextField(
      controller: _passwordController,
      label: 'Password',
      icon: Icons.lock_rounded,
      isDark: isDark,
      isPassword: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
    
    // Build the confirm password field (only for signup)
    Widget? confirmPasswordField;
    if (!_isLogin) {
      confirmPasswordField = _buildTextField(
        controller: _confirmPasswordController,
        label: 'Confirm Password',
        icon: Icons.lock_outline_rounded,
        isDark: isDark,
        isPassword: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      );
    }
    
    // Build social login button
    Widget _buildSocialButton({
      required String icon,
      required VoidCallback onPressed,
      required bool isDark,
    }) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Center(
              child: Image.asset(
                icon,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.error_outline,
                  color: isDark ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Build the email field
    final emailField = _buildTextField(
      controller: _emailController,
      label: 'Email',
      icon: Icons.email_rounded,
      isDark: isDark,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
    
    // Build the password field
    final passwordField = _buildTextField(
      controller: _passwordController,
      label: 'Password',
      icon: Icons.lock_rounded,
      isDark: isDark,
      isPassword: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
    
    // Build the confirm password field (only for signup)
    Widget? confirmPasswordField;
    if (!_isLogin) {
      confirmPasswordField = _buildTextField(
        controller: _confirmPasswordController,
        label: 'Confirm Password',
        icon: Icons.lock_outline_rounded,
        isDark: isDark,
        isPassword: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      );
    }
    
    // Create a list of widgets that will be built based on the form state
    final formChildren = <Widget>[
      // Email Field
      TextFormField(
        controller: _emailController,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.email_rounded,
            color: isDark ? Colors.green.shade400 : Colors.green.shade700,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.green.shade400 : Colors.green.shade700,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      ),
      
      const SizedBox(height: 20),
      
      // Password Field
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: GoogleFonts.poppins(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            Icons.lock_rounded,
            color: isDark ? Colors.green.shade400 : Colors.green.shade700,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.visibility_off_rounded,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
            onPressed: () {},
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.green.shade400 : Colors.green.shade700,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                  ? [
                      const Color(0xFF1B5E20),
                      const Color(0xFF2E7D32),
                      const Color(0xFF388E3C),
                    ]
                  : [
                      Colors.white,
                      const Color(0xFFE8F5E9),
                    ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and Welcome Text
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.eco,
                            size: 60,
                            color: isDark ? Colors.white : Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'GreenSpace',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.green.shade700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin 
                              ? 'Sign in to continue' 
                              : 'Create your account',
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Auth Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            emailField,
                            const SizedBox(height: 20),
                            passwordField,
                            if (confirmPasswordField != null) ...[
                              const SizedBox(height: 20),
                              confirmPasswordField,
                            ],
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: GoogleFonts.poppins(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_rounded,
                                  color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            const SizedBox(height: 20),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: GoogleFonts.poppins(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_rounded,
                                  color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.visibility_off_rounded,
                                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                  onPressed: () {},
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            
    ];
    
    // Add confirm password field if in signup mode
    if (!_isLogin) {
      formChildren.addAll([
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: GoogleFonts.poppins(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: isDark ? Colors.green.shade400 : Colors.green.shade700,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _confirmPasswordController,
                                style: GoogleFonts.poppins(
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: GoogleFonts.poppins(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 28),
                            
                            // Sign In/Up Button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.green.shade700 : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Sign In' : 'Create Account',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Toggle between Sign In and Sign Up
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin 
                                      ? 'Don\'t have an account? ' 
                                      : 'Already have an account? ',
                                  style: GoogleFonts.poppins(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isLogin = !_isLogin;
                                            _formKey.currentState?.reset();
                                          });
                                        },
                                  child: Text(
                                    _isLogin ? 'Sign Up' : 'Sign In',
                                    style: GoogleFonts.poppins(
                                      color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (_isLogin) ...[
                              const SizedBox(height: 24),
                              
                              // Divider with "or"
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'or continue with',
                                      style: GoogleFonts.poppins(
                                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Social Login Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Google
                                  _buildSocialButton(
                                    icon: 'assets/images/google.png',
                                    onPressed: () {},
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 16),
                                  // Apple
                                  _buildSocialButton(
                                    icon: 'assets/images/apple.png',
                                    onPressed: () {},
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 16),
                                  // Facebook
                                  _buildSocialButton(
                                    icon: 'assets/images/facebook.png',
                                    onPressed: () {},
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
