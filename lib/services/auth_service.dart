import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService() : _supabase = Supabase.instance.client {
    // Get the URL from Supabase client's options
    final url = _supabase.rest.url;
    if (url == null || url.isEmpty || !url.startsWith('http')) {
      debugPrint('Warning: Invalid or missing Supabase URL: $url');
    } else {
      debugPrint('Supabase initialized with URL: $url');
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    debugPrint('Signup request for: $email');
    debugPrint('Supabase URL: ${_supabase.rest.url}');
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
          'error': 'validation_error',
        };
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
          'error': 'invalid_email',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
          'error': 'weak_password',
        };
      }

      // For now, let's skip the redirect URL to get signup working
      // We'll handle email confirmation separately
      debugPrint('Starting signup process for: $email');
      
      try {
        debugPrint('Attempting to sign up user: $email');
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        debugPrint('Signup response received for: ${response.user?.email}');

        if (response.user == null) {
          debugPrint('Signup failed: No user in response');
          return {
            'success': false,
            'message': 'Failed to create user',
            'error': 'signup_failed',
          };
        }

        debugPrint('User created successfully: ${response.user!.id}');
        return {
          'success': true,
          'message': 'Sign up successful! Please check your email to verify your account.',
          'user': response.user,
          'session': response.session,
        };
      } catch (e) {
        debugPrint('Error during signup: $e');
        return {
          'success': false,
          'message': 'An error occurred during sign up: ${e.toString()}',
          'error': e.toString(),
        };
      }
    } on AuthException catch (e) {
      // Handle Supabase auth errors
      String errorMessage = 'An error occurred during sign up';
      
      switch (e.message) {
        case 'User already registered':
          errorMessage = 'This email is already registered. Please log in instead.';
          break;
        case 'Invalid login credentials':
          errorMessage = 'Invalid email or password';
          break;
        case 'Email not confirmed':
          errorMessage = 'Please confirm your email before signing in';
          break;
        // Add more specific error cases as needed
      }

      return {
        'success': false,
        'message': errorMessage,
        'error': e.message,
        'code': e.statusCode.toString(),
      };
    } catch (e) {
      // Handle other types of errors
      return {
        'success': false,
        'message': 'An unexpected error occurred',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('Sign-in attempt for: $email');
    
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
          'error': 'validation_error',
        };
      }

      debugPrint('Attempting to sign in user: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('Sign-in response received for: ${response.user?.email}');

      if (response.user == null) {
        debugPrint('Sign-in failed: No user in response');
        return {
          'success': false,
          'message': 'Failed to sign in. Please try again.',
          'error': 'signin_failed',
        };
      }

      debugPrint('User signed in successfully: ${response.user!.id}');
      return {
        'success': true,
        'message': 'Sign in successful!',
        'user': response.user,
        'session': response.session,
      };
    } on AuthException catch (e) {
      // Handle Supabase auth errors
      String errorMessage = 'An error occurred during sign in';
      
      switch (e.message) {
        case 'Invalid login credentials':
          errorMessage = 'Invalid email or password';
          break;
        case 'Email not confirmed':
          errorMessage = 'Please confirm your email before signing in';
          break;
        case 'Invalid email or password':
          errorMessage = 'Invalid email or password';
          break;
        // Add more specific error cases as needed
      }

      debugPrint('Auth error during sign in: ${e.message}');
      return {
        'success': false,
        'message': errorMessage,
        'error': e.message,
        'code': e.statusCode.toString(),
      };
    } catch (e) {
      // Handle other types of errors
      debugPrint('Unexpected error during sign in: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred during sign in',
        'error': e.toString(),
      };
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
