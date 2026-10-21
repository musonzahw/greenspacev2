import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import 'create_event_screen.dart';

class NewEventDrawer extends StatelessWidget {
  final Function() onEventCreated;
  final bool isDark;

  const NewEventDrawer({
    Key? key,
    required this.onEventCreated,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16.0)),
      ),
      child: const CreateEventScreen(),
    );
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Upcoming', 'Popular', 'Nearby'];
  
  // Events list will be loaded from the provider
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventSubscription();
  }

  void _setupEventSubscription() {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    _eventsSubscription = eventProvider.getEvents().listen(
      (events) {
        if (mounted) {
          setState(() {
            _events = _processEvents(events);
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load events: $error';
            _isLoading = false;
          });
        }
      },
    );
  }
  
  List<Map<String, dynamic>> _processEvents(dynamic eventsData) {
    try {
      if (eventsData is! List) return [];
      
      return eventsData.map<Map<String, dynamic>>((event) {
        try {
          final eventMap = event is Map ? Map<String, dynamic>.from(event) : {};
          return {
            'id': eventMap['id']?.toString() ?? '',
            'title': eventMap['title']?.toString() ?? 'Untitled Event',
            'description': eventMap['description']?.toString() ?? '',
            'date': _parseDate(eventMap['date']),
            'location': eventMap['location']?.toString() ?? 'Location not specified',
            'category': eventMap['category']?.toString() ?? 'General',
            'attending': (eventMap['participants'] is List ? eventMap['participants'].length : 0),
            'isAttending': false,
          };
        } catch (e) {
          return _createErrorEvent('Error processing event: $e');
        }
      }).toList();
    } catch (e) {
      return [_createErrorEvent('Failed to process events: $e')];
    }
  }
  
  Map<String, dynamic> _createErrorEvent(String message) {
    return {
      'id': 'error-${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Error Loading Event',
      'description': message,
      'date': DateTime.now(),
      'location': 'Unknown',
      'category': 'Error',
      'attending': 0,
      'isAttending': false,
    };
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Format date to a readable string
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  // Format time to AM/PM
  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  // Filter events based on search and category
  List<Map<String, dynamic>> get _filteredEvents {
    if (_isLoading) return [];
    if (_error != null) return [];
    
    final filtered = _events.where((event) {
      final title = event['title']?.toString().toLowerCase() ?? '';
      final matchesSearch = title.contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || 
          (event['category']?.toString() ?? '') == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    return filtered;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openNewEventDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      endDrawer: NewEventDrawer(
        isDark: isDark,
        onEventCreated: () {
          if (mounted) setState(() {});
          Navigator.of(context).pop(); // Close the drawer
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0), // Add padding to account for bottom navigation bar
        child: FloatingActionButton.extended(
          onPressed: _openNewEventDrawer,
          backgroundColor: Colors.green,
          elevation: 6.0,
          icon: const Icon(Icons.add, color: Colors.white, size: 28.0),
          label: const Text('New Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Categories
            SizedBox(
              height: 50.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDark ? Colors.green[800]! : Colors.green[100]!)
                            : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? (isDark ? Colors.green[600]! : Colors.green[300]!)
                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? Colors.white : Colors.green[900])
                                    : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Event count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Total Events: ${_filteredEvents.length}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Events list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _filteredEvents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_busy,
                                    size: 64.0,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    'No events found',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemCount: _filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = _filteredEvents[index];
                                return _buildEventCard(context, event);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _showEventDetails(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Image
            Container(
              height: 120.0,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              ),
              child: Center(
                child: Icon(
                  _getEventIcon(event['title']),
                  size: 48.0,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'],
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Row(
                        children: [
                          // Action Buttons
                          Row(
                            children: [
                              // Edit Button
                              InkWell(
                                onTap: () => _navigateToEditEvent(event),
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    size: 16.0,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              // Delete Button
                              InkWell(
                                onTap: () => _confirmDeleteEvent(context, event['id'], event['title']),
                                borderRadius: BorderRadius.circular(12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16.0,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8.0),
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              event['category'],
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8.0),
                  
                  // Date and Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.0,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '${_formatDate(event['date'])} • ${_formatTime(event['date'])}',
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4.0),
                  
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16.0,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        event['location'],
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12.0),
                  
                  // Attendees and Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16.0,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${event['attending']} attending',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            event['isAttending'] = !event['isAttending'];
                            if (event['isAttending']) {
                              event['attending']++;
                            } else {
                              event['attending']--;
                            }
                          });
                        },
                        icon: Icon(
                          event['isAttending'] 
                              ? Icons.check_circle_outline 
                              : Icons.add_circle_outline,
                        ),
                        label: Text(
                          event['isAttending'] ? 'Attending' : 'Attend',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event['isAttending']
                              ? Colors.green.withOpacity(0.1)
                              : theme.colorScheme.primary,
                          foregroundColor: event['isAttending']
                              ? Colors.green
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60.0,
                    height: 4.0,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                
                // Event Image
                Container(
                  height: 200.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Icon(
                      _getEventIcon(event['title']),
                      size: 64.0,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Title and Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event['title'],
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        event['category'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
                
                // Date and Time
                _buildDetailRow(Icons.calendar_today, 
                    '${_formatDate(event['date'])} • ${_formatTime(event['date'])}'),
                
                // Location
                _buildDetailRow(Icons.location_on, event['location']),
                
                // Attendees
                _buildDetailRow(
                  Icons.people,
                  '${event['attending']} people attending',
                ),
                
                const SizedBox(height: 16.0),
                
                // Description
                const Text(
                  'About This Event',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  event['description'],
                  style: const TextStyle(
                    fontSize: 16.0,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24.0),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            event['isAttending'] = !event['isAttending'];
                            if (event['isAttending']) {
                              event['attending']++;
                            } else {
                              event['attending']--;
                            }
                          });
                        },
                        icon: Icon(
                          event['isAttending'] 
                              ? Icons.check_circle_outline 
                              : Icons.add_circle_outline,
                        ),
                        label: Text(
                          event['isAttending'] ? 'Attending' : 'Attend Event',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: event['isAttending']
                              ? Colors.green.withOpacity(0.1)
                              : Theme.of(context).colorScheme.primary,
                          foregroundColor: event['isAttending']
                              ? Colors.green
                              : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    IconButton(
                      onPressed: () {
                        // Share functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sharing event...')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.all(16.0),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.0,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 14.0),
              ),
              
              const SizedBox(height: 16.0),
              
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 14.0),
              ),
              
              const SizedBox(height: 16.0),
              
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () {
                  // Date picker would go here
                },
                controller: TextEditingController(
                  text: '${_formatDate(DateTime.now().add(const Duration(days: 7)))} • ${_formatTime(DateTime.now().add(const Duration(days: 7)))}',
                ),
                style: const TextStyle(fontSize: 14.0),
              ),
              
              const SizedBox(height: 16.0),
              
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.location_on),
                ),
                style: const TextStyle(fontSize: 14.0),
              ),
              
              const SizedBox(height: 16.0),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: 'Environment',
                items: ['Environment', 'Cleanup', 'Education', 'Other']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Create event logic would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event created successfully!')),
              );
            },
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  void _navigateToEditEvent(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          eventToEdit: event,
          onEventCreated: () {
            // Refresh events after editing
            _setupEventSubscription();
            if (mounted) {
              _showSnackBar('Event updated successfully');
            }
          },
        ),
      ),
    );
  }
  
  Future<void> _confirmDeleteEvent(BuildContext context, String eventId, String eventTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "$eventTitle"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        await eventProvider.deleteEvent(eventId);
        
        if (mounted) {
          _showSnackBar('Event deleted successfully');
          _setupEventSubscription(); // Refresh the list
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to delete event: $e');
        }
      }
    }
  }
  
  // Helper method to get appropriate icon based on event title
  IconData _getEventIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('tree') || lowerTitle.contains('plant')) {
      return Icons.nature;
    } else if (lowerTitle.contains('beach') || lowerTitle.contains('clean')) {
      return Icons.cleaning_services;
    } else if (lowerTitle.contains('recycle')) {
      return Icons.recycling;
    } else if (lowerTitle.contains('workshop') || lowerTitle.contains('learn')) {
      return Icons.school;
    } else {
      return Icons.event;
    }
  }
}
