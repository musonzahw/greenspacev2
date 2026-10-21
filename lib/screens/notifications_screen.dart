import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notification data
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New Soil Analysis Complete',
      'message': 'Your soil sample has been analyzed. Tap to view results.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'isRead': false,
      'type': 'soil_analysis',
    },
    {
      'id': '2',
      'title': 'New Comment on Your Post',
      'message': 'JohnDoe commented on your forum post about organic farming.',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': true,
      'type': 'comment',
    },
    {
      'id': '3',
      'title': 'Upcoming Event Reminder',
      'message': 'Community Garden Workshop starts in 1 hour!',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'isRead': true,
      'type': 'event',
    },
    {
      'id': '4',
      'title': 'New Article Published',
      'message': 'Check out our latest article on sustainable farming techniques.',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'isRead': true,
      'type': 'article',
    },
    {
      'id': '5',
      'title': 'Report Status Update',
      'message': 'Your recent report has been reviewed and action has been taken.',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'isRead': true,
      'type': 'report',
    },
  ];

  // Mark all notifications as read
  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  // Get icon based on notification type
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'soil_analysis':
        return Icons.analytics;
      case 'comment':
        return Icons.comment;
      case 'event':
        return Icons.event;
      case 'article':
        return Icons.article;
      case 'report':
        return Icons.report_problem;
      default:
        return Icons.notifications;
    }
  }

  // Get color based on notification type
  Color _getNotificationColor(String type, ThemeData theme) {
    switch (type) {
      case 'soil_analysis':
        return theme.colorScheme.primary;
      case 'comment':
        return Colors.blue;
      case 'event':
        return Colors.orange;
      case 'article':
        return Colors.green;
      case 'report':
        return Colors.red;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all as read'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you get notifications, they\'ll appear here',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isRead = notification['isRead'] as bool;
                
                return Dismissible(
                  key: Key(notification['id']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      _notifications.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notification removed'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            setState(() {
                              _notifications.insert(index, notification);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification['type'], theme)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification['type']),
                        color: _getNotificationColor(notification['type'], theme),
                      ),
                    ),
                    title: Text(
                      notification['title'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message']),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(notification['timestamp']),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    trailing: !isRead
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () {
                      // Mark as read when tapped
                      if (!isRead) {
                        setState(() {
                          notification['isRead'] = true;
                        });
                      }
                      // TODO: Handle notification tap (navigate to relevant screen)
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh notifications
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refreshing notifications')),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
