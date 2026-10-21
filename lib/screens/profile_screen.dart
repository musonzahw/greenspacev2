import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data - will be populated from the auth service
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _userData = {
      'name': 'Guest User',
      'email': 'guest@example.com',
      'joinDate': 'Member since today',
      'bio': 'Environmental enthusiast.',
      'avatarUrl': 'https://randomuser.me/api/portraits/lego/1.jpg',
      'stats': {
        'soilScans': 0,
        'eventsAttended': 0,
        'reportsSubmitted': 0,
        'forumPosts': 0,
      },
    };

    // Try to get user data from auth service
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      setState(() {
        _userData = {
          'name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
          'email': user.email ?? 'No email',
          'joinDate': 'Member since ${DateTime.now().year}',
          'bio': _userData['bio'], // Keep existing bio
          'avatarUrl': _userData['avatarUrl'], // Keep existing avatar
          'stats': _userData['stats'], // Keep existing stats
        };
      });
    }
  }

  // Sample saved soil analyses
  final List<Map<String, dynamic>> _savedAnalyses = [
    {
      'id': '1',
      'date': '2025-10-15',
      'soilType': 'Loamy Soil',
      'phLevel': '6.5',
      'location': 'Backyard Garden',
      'imageUrl': 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=300',
    },
    {
      'id': '2',
      'date': '2025-10-10',
      'soilType': 'Sandy Soil',
      'phLevel': '6.0',
      'location': 'Community Garden',
      'imageUrl': 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=300',
    },
    {
      'id': '3',
      'date': '2025-10-05',
      'soilType': 'Clay Soil',
      'phLevel': '7.0',
      'location': 'Front Yard',
      'imageUrl': 'https://images.unsplash.com/photo-1605000797499-95a51c5269ae?w=300',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(theme, colorScheme),
            
            const SizedBox(height: 24),
            
            // Stats
            _buildStatsSection(theme, colorScheme),
            
            const SizedBox(height: 24),
            
            // Bio
            if (_userData['bio'] != null && _userData['bio'].isNotEmpty)
              _buildBioSection(theme, colorScheme),
            
            const SizedBox(height: 24),
            
            // Saved Soil Analyses
            _buildSavedAnalysesSection(theme, colorScheme),
            
            const SizedBox(height: 24),
            
            // Account Actions (includes logout button)
            _buildAccountActions(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(_userData['avatarUrl']),
          backgroundColor: colorScheme.surfaceVariant,
        ),
        
        const SizedBox(width: 16),
        
        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userData['name'],
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                _userData['email'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                _userData['joinDate'],
                style: theme.textTheme.bodySmall,
              ),
              
              const SizedBox(height: 12),
              
              ElevatedButton(
                onPressed: () {
                  // Edit profile
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Edit Profile'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: FontAwesomeIcons.microscope,
              label: 'Soil Scans',
              value: _userData['stats']['soilScans'].toString(),
              theme: theme,
            ),
            _buildStatItem(
              icon: FontAwesomeIcons.calendarCheck,
              label: 'Events',
              value: _userData['stats']['eventsAttended'].toString(),
              theme: theme,
            ),
            _buildStatItem(
              icon: FontAwesomeIcons.flag,
              label: 'Reports',
              value: _userData['stats']['reportsSubmitted'].toString(),
              theme: theme,
            ),
            _buildStatItem(
              icon: FontAwesomeIcons.comment,
              label: 'Posts',
              value: _userData['stats']['forumPosts'].toString(),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildBioSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _userData['bio'],
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSavedAnalysesSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Saved Soil Analyses',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // View all analyses
              },
              child: const Text('View All'),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedAnalyses.length,
            itemBuilder: (context, index) {
              final analysis = _savedAnalyses[index];
              return _buildAnalysisCard(analysis, theme, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
      Map<String, dynamic> analysis, 
      ThemeData theme, 
      ColorScheme colorScheme
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analysis Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                analysis['imageUrl'],
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  color: colorScheme.surfaceVariant,
                  child: const Icon(Icons.terrain, size: 40),
                ),
              ),
            ),
            
            // Analysis Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis['soilType'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'pH: ${analysis['phLevel']}',
                    style: theme.textTheme.bodySmall,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    analysis['location'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Activity History'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to activity history
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.bookmark_border),
          title: const Text('Saved Items'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to saved items
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to notifications
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to help & support
          },
        ),
        
        const SizedBox(height: 16),
        
        OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        // Navigate to auth screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }
}
