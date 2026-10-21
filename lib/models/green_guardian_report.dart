import 'dart:convert';

class GreenGuardianReport {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String locationText;
  final List<String>? mediaUrls;
  final List<String>? mediaTypes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  GreenGuardianReport({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.locationText,
    this.mediaUrls,
    this.mediaTypes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GreenGuardianReport.fromJson(Map<String, dynamic> json) {
    try {
      return GreenGuardianReport(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        locationText: json['location_text']?.toString() ?? '',
        mediaUrls: json['media_urls'] != null 
            ? List<String>.from((json['media_urls'] as List).map((x) => x.toString()))
            : null,
        mediaTypes: json['media_types'] != null
            ? List<String>.from((json['media_types'] as List).map((x) => x.toString()))
            : null,
        status: json['status']?.toString() ?? 'pending',
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'].toString()).toLocal()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString()).toLocal()
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('Error parsing GreenGuardianReport from JSON: $e');
      print('JSON: ${jsonEncode(json)}');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'location_text': locationText,
      'media_urls': mediaUrls,
      'media_types': mediaTypes,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
