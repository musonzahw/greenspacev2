import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/green_guardian_report.dart';

class GreenGuardianService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload a file to storage
  Future<String> uploadFile(File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'reports/$fileName';
      
      await _supabase.storage
          .from('green_guardian_media')
          .upload(filePath, file);

      final String publicUrl = _supabase.storage
          .from('green_guardian_media')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading file to green_guardian_media bucket: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // Submit a new report
  Future<GreenGuardianReport> submitReport({
    required String title,
    required String description,
    required String category,
    required String locationText,
    File? image,
    required String userId,
  }) async {
    try {
      print('🔄 Starting report submission...');
      print('📝 Title: $title');
      print('📄 Description: $description');
      print('🏷️ Category: $category');
      print('📍 Location: $locationText');
      print('👤 User ID: $userId');
      print('🖼️ Image provided: ${image != null}');

      String? imageUrl;
      String? mediaType;

      // Upload image if provided
      if (image != null) {
        try {
          print('📤 Uploading image...');
          imageUrl = await uploadFile(image);
          mediaType = 'image/${image.path.split('.').last}';
          print('✅ Image uploaded successfully. URL: $imageUrl');
        } catch (e) {
          print('❌ Error uploading image: $e');
          // Continue without the image if upload fails
        }
      }

      // Prepare report data
      final reportData = {
        'title': title,
        'description': description,
        'category': category,
        'location_text': locationText,
        'media_urls': imageUrl != null ? [imageUrl] : null,
        'media_types': mediaType != null ? [mediaType] : null,
        'user_id': userId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      print('📤 Inserting report into database...');
      print('📋 Report data: $reportData');

      // Insert the report
      final response = await _supabase
          .from('green_guardian_reports')
          .insert(reportData)
          .select()
          .single();

      print('✅ Report inserted successfully!');
      print('📊 Response: $response');

      return GreenGuardianReport.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ Error in submitReport:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get reports for the current user
  Future<List<GreenGuardianReport>> getUserReports(String userId) async {
    try {
      final response = await _supabase
          .from('green_guardian_reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GreenGuardianReport.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  // Get a single report by ID
  Future<GreenGuardianReport> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('green_guardian_reports')
          .select()
          .eq('id', reportId)
          .single();

      return GreenGuardianReport.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  // Update an existing report
  Future<GreenGuardianReport> updateReport({
    required String reportId,
    required String title,
    required String description,
    required String category,
    required String locationText,
    File? newImage,
    required String userId,
  }) async {
    try {
      print('🔄 Starting report update...');
      print('📝 Report ID: $reportId');
      print('📝 Title: $title');
      print('📄 Description: $description');
      print('🏷️ Category: $category');
      print('📍 Location: $locationText');

      // Get existing report to preserve existing media
      final existingReport = await getReportById(reportId);
      
      String? imageUrl = existingReport.mediaUrls?.isNotEmpty == true 
          ? existingReport.mediaUrls!.first 
          : null;
      String? mediaType = existingReport.mediaTypes?.isNotEmpty == true
          ? existingReport.mediaTypes!.first
          : null;

      // Upload new image if provided
      if (newImage != null) {
        try {
          print('📤 Uploading new image...');
          imageUrl = await uploadFile(newImage);
          mediaType = 'image/${newImage.path.split('.').last}';
          print('✅ New image uploaded successfully. URL: $imageUrl');
        } catch (e) {
          print('❌ Error uploading new image: $e');
          // Continue with existing image if upload fails
        }
      }

      // Prepare update data
      final updateData = {
        'title': title,
        'description': description,
        'category': category,
        'location_text': locationText,
        'media_urls': imageUrl != null ? [imageUrl] : null,
        'media_types': mediaType != null ? [mediaType] : null,
        'status': 'pending', // Reset status when updating
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('🔄 Updating report in database...');
      print('📋 Update data: $updateData');

      // Update the report
      final response = await _supabase
          .from('green_guardian_reports')
          .update(updateData)
          .eq('id', reportId)
          .eq('user_id', userId) // Ensure user owns the report
          .select()
          .single();

      print('✅ Report updated successfully!');
      return GreenGuardianReport.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ Error in updateReport:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to update report: $e');
    }
  }
}
