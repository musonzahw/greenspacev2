import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'forum_screen.dart';
import 'green_guardian_screen.dart';
import 'news_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'test_supabase_screen.dart';
import 'image_recognition_screen.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showReportsTab = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
    
    // Initialize screens
    _initializeScreens();
  }
  
  void _initializeScreens() {
    _screens = [
      // Index 0: Dashboard
      DashboardScreen(
        onNavigateToTab: (index) {
          if (index >= 0 && index < _screens.length) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        onViewReports: () {
          setState(() {
            _selectedIndex = 4; // Green Guardian tab index
            _showReportsTab = true;
            _screens[4] = GreenGuardianScreen(showReportsTab: true);
          });
        },
      ),
      // Index 1: Forum
      const ForumScreen(),
      // Index 2: Events
      const EventsScreen(),
      // Index 3: News
      const NewsScreen(),
      // Index 4: Green Guardian
      GreenGuardianScreen(showReportsTab: _showReportsTab),
      // Index 5: Image Recognition
      const ImageRecognitionScreen(),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Build navigation bar item
  Widget _buildNavItem(IconData icon, String label, int index, {bool isActionButton = false}) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.unselectedWidgetColor.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.unselectedWidgetColor.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation items with custom styling
  List<BottomNavigationBarItem> get _bottomNavItems {
    return [
      // Index 0: Home (Dashboard)
      BottomNavigationBarItem(
        icon: _buildNavItem(Icons.home_rounded, 'Home', 0),
        label: 'Home',
      ),
      // Index 1: Forum
      BottomNavigationBarItem(
        icon: _buildNavItem(Icons.forum_rounded, 'Forum', 1),
        label: 'Forum',
      ),
      // Index 2: Events (Middle button)
      const BottomNavigationBarItem(
        icon: SizedBox.shrink(),
        label: '',
      ),
      // Index 3: News
      BottomNavigationBarItem(
        icon: _buildNavItem(Icons.article_rounded, 'News', 3),
        label: 'News',
      ),
      // Index 4: Green Guardian
      BottomNavigationBarItem(
        icon: _buildNavItem(Icons.eco_rounded, 'Guardian', 4),
        label: 'Guardian',
      ),
      // Index 5: Image Recognition
      BottomNavigationBarItem(
        icon: _buildNavItem(Icons.camera_alt_rounded, 'AI', 5),
        label: 'AI',
      ),
    ];
  }
  
  // Method to set the current page index
  void setPage(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Removed duplicate initState method

  void _onItemTapped(int index) {
    if (index == 2) return; // Skip the middle button index
    
    setState(() {
      _selectedIndex = index;
      // Reset showReportsTab when navigating away from Green Guardian tab
      if (index != 4) {
        _showReportsTab = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Custom floating action button for the middle tab
    String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Forum';
      case 2:
        return 'Events';
      case 3:
        return 'News';
      case 4:
        return 'Green Guardian';
      case 5:
        return 'Image Recognition';
      default:
        return 'Greenspace';
    }
  }

  Widget _buildMiddleNavButton() {
      return GestureDetector(
        onTap: () => _onItemTapped(2), // Events tab
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true, // Allows body to extend behind the navigation bar
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _getTitleForIndex(_selectedIndex),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: theme.iconTheme.color,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          // Theme Toggle Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 26,
            ),
            onPressed: () {
              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
              themeProvider.toggleTheme();
            },
          ),
          // Profile
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                      color: theme.cardColor,
                    ),
                    child: Icon(
                      Icons.person,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _screens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home (Dashboard) - Index 0
                _buildNavItem(Icons.home_rounded, 'Home', 0),
                
                // Forum - Index 1
                _buildNavItem(Icons.forum_rounded, 'Forum', 1),
                
                // Middle action button - Index 2 (Events)
                _buildMiddleNavButton(),
                
                // News - Index 3
                _buildNavItem(Icons.article_rounded, 'News', 3),
                
                // Guardian - Index 4
                _buildNavItem(Icons.eco_rounded, 'Guardian', 4),
                
                // Image Recognition - Index 5
                _buildNavItem(Icons.camera_alt_rounded, 'AI', 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
