import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/event_provider.dart';

class TestSupabaseScreen extends StatelessWidget {
  const TestSupabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Supabase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final newEvent = await eventProvider.createEvent({
                          'title': 'Test Event ${DateTime.now().second}',
                          'description': 'This is a test event',
                          'date': DateTime.now()
                              .add(const Duration(days: 1))
                              .toIso8601String(),
                          'location': 'Test Location',
                          'category': 'Test',
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event created successfully!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text('Create Test Event'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EventListScreen(),
                        ),
                      );
                    },
                    child: const Text('View Events'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventsStream = Provider.of<EventProvider>(context).getEvents();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: eventsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;

          if (events.isEmpty) {
            return const Center(child: Text('No events found'));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(event['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event['description'] ?? 'No Description'),
                      Text('Location: ${event['location']}'),
                      Text('Date: ${event['date']}'),
                      Text('Participants: ${(event['participants'] as List<dynamic>?)?.length ?? 0}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
