import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    // Save the preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    
    notifyListeners();
  }
  
  // Load the saved theme preference
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }
  
  // Get the appropriate theme based on the current mode
  ThemeData getTheme(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark || 
                   (_themeMode == ThemeMode.system && 
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
    
    return isDark ? _darkTheme : _lightTheme;
  }
  
  // Light theme
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2E7D32),
      primaryContainer: const Color(0xFFA5D6A7),
      secondary: const Color(0xFF81C784),
      surface: Colors.white,
      background: Colors.grey.shade50,
      onBackground: Colors.black87,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2E7D32),
      foregroundColor: Colors.white,
    ),
  );
  
  // Dark theme
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF81C784),
      primaryContainer: Color(0xFF2E7D32),
      secondary: Color(0xFF4CAF50),
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      onBackground: Colors.white,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}
