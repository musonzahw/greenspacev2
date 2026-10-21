import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'soil_scan_screen.dart';
import 'report_screen.dart';
import 'green_guardian_reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback onViewReports;
  
  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // List of dashboard items
    final List<Map<String, dynamic>> dashboardItems = [
      {
        'title': 'Latest Environmental News',
        'icon': Icons.article,
        'description': 'Stay updated with the latest environmental news',
        'color': Colors.blue.shade700,
        'onTap': () {
          // Navigate to news tab (index 3 in the bottom navigation)
          if (onNavigateToTab != null) {
            onNavigateToTab(3); // This should match the index of NewsScreen in home_screen.dart
          }
        },
      },
      {
        'title': 'Soil Scan',
        'icon': FontAwesomeIcons.microscope,
        'description': 'Analyze soil quality using your camera',
        'color': colorScheme.primary,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SoilScanScreen()),
          );
        },
      },
      {
        'title': 'Community Forum',
        'icon': FontAwesomeIcons.comments,
        'description': 'Discuss environmental topics with the community',
        'color': Colors.blue,
        'onTap': () {
          onNavigateToTab(1); // Index 1 is the Forum tab
        },
      },
      {
        'title': 'Events',
        'icon': FontAwesomeIcons.calendarAlt,
        'description': 'Find and join environmental events',
        'color': Colors.orange,
        'onTap': () {
          onNavigateToTab(2); // Index 2 is the Events tab
        },
      },
      {
        'title': 'Green Guardian',
        'icon': FontAwesomeIcons.leaf,
        'description': 'Report environmental concerns in your area',
        'color': Colors.green,
        'onTap': () {
          onNavigateToTab(3); // Index 3 is the Green Guardian tab
        },
      },
      {
        'title': 'View Reports',
        'icon': FontAwesomeIcons.clipboardList,
        'description': 'View and manage your submitted reports',
        'color': Colors.teal,
        'onTap': () {
          // Navigate directly to the reports screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GreenGuardianReportsScreen(),
            ),
          );
        },
      },
      {
        'title': 'Report Issue',
        'icon': FontAwesomeIcons.flag,
        'description': 'Report inappropriate content or issues',
        'color': Colors.red,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReportScreen()),
          );
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Greenspace'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Greenspace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your environmental companion for a better tomorrow',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: dashboardItems.length,
                itemBuilder: (context, index) {
                  final item = dashboardItems[index];
                  return _buildDashboardCard(
                    context,
                    title: item['title'] as String,
                    icon: item['icon'] as IconData,
                    description: item['description'] as String,
                    color: item['color'] as Color,
                    onTap: item['onTap'] as VoidCallback,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
