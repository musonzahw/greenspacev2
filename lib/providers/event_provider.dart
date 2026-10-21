import 'package:flutter/foundation.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<Map<String, dynamic>>> getEvents() {
    return _eventService.getEvents();
  }

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    _setLoading(true);
    try {
      await _eventService.createEvent(eventData);
      _error = null;
    } catch (e) {
      _error = 'Failed to create event: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      await _eventService.updateEvent(eventId, updates);
      _error = null;
    } catch (e) {
      _error = 'Failed to update event: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _setLoading(true);
    try {
      await _eventService.deleteEvent(eventId);
      _error = null;
    } catch (e) {
      _error = 'Failed to delete event: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleAttendance(String eventId, String userId) async {
    _setLoading(true);
    try {
      await _eventService.toggleAttendance(eventId, userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to update attendance: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
