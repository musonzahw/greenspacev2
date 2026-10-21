import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all events
  Stream<List<Map<String, dynamic>>> getEvents() {
    return _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date')
        .map((events) => events.map((event) => _parseEvent(event)).toList());
  }

  // Get a single event by ID
  Future<Map<String, dynamic>?> getEvent(String id) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('id', id)
          .single();
      return _parseEvent(response);
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  // Create a new event
  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> event) async {
    try {
      final user = _supabase.auth.currentUser;
      
      // Create a new map without the created_by field for testing
      final newEvent = {
        'title': event['title'],
        'description': event['description'],
        'date': event['date'],
        'location': event['location'],
        'category': event['category'],
        'participants': <String>[], // Empty array for participants
      };
      
      // Only add created_by if user is authenticated
      if (user != null) {
        newEvent['created_by'] = user.id;
        newEvent['participants'] = [user.id];
      }

      final response = await _supabase
          .from('events')
          .insert(newEvent)
          .select()
          .single();

      return _parseEvent(response);
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  // Update an existing event
  Future<Map<String, dynamic>> updateEvent(
      String id, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('events')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      return _parseEvent(response);
    } catch (e) {
      print('Error updating event: $e');
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String id) async {
    try {
      await _supabase.from('events').delete().eq('id', id);
    } catch (e) {
      print('Error deleting event: $e');
      rethrow;
    }
  }

  // Toggle user attendance for an event
  Future<void> toggleAttendance(String eventId, String userId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) throw Exception('Event not found');

      final participants = List<String>.from(event['participants'] ?? []);
      
      if (participants.contains(userId)) {
        // Remove user from participants
        await _supabase.rpc('array_remove', params: {
          'arr': participants,
          'x': userId,
        });
      } else {
        // Add user to participants
        participants.add(userId);
        await _supabase
            .from('events')
            .update({'participants': participants})
            .eq('id', eventId);
      }
    } catch (e) {
      print('Error toggling attendance: $e');
      rethrow;
    }
  }

  // Helper method to parse event data
  Map<String, dynamic> _parseEvent(Map<String, dynamic> event) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    return {
      'id': event['id'],
      'title': event['title'] ?? 'No Title',
      'description': event['description'] ?? '',
      'date': parseDate(event['date']),
      'location': event['location'] ?? 'No Location',
      'category': event['category'] ?? 'Uncategorized',
      'createdBy': event['created_by'],
      'participants': List<String>.from(event['participants'] ?? []),
      'createdAt': parseDate(event['created_at']),
      'updatedAt': parseDate(event['updated_at']),
    };
  }
}
