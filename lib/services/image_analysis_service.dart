import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageAnalysisService {
  static final ImageAnalysisService _instance = ImageAnalysisService._internal();
  factory ImageAnalysisService() => _instance;
  ImageAnalysisService._internal();

  final String _backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8080';

  // Test backend connection
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/ping'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend connection test failed: $e');
      return false;
    }
  }

  // Analyze single image
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Prepare request data
      final requestData = {
        'frame': 'data:image/jpeg;base64,$base64Image',
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
        'analysis_type': 'single_image',
      };

      // Send to backend
      final response = await http.post(
        Uri.parse('$_backendUrl/analyze-frame'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Analysis failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing image: $e');
      throw Exception('Failed to analyze image: $e');
    }
  }

  // Analyze frame from base64 string (for real-time analysis)
  Future<Map<String, dynamic>> analyzeFrame(String base64Frame) async {
    try {
      final requestData = {
        'frame': base64Frame,
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000,
        'analysis_type': 'real-time',
      };

      final response = await http.post(
        Uri.parse('$_backendUrl/analyze-frame'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Frame analysis failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error analyzing frame: $e');
      throw Exception('Failed to analyze frame: $e');
    }
  }

  // Format analysis results for display
  String formatAnalysisResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    // Object detections
    final detections = results['detections'] as List? ?? [];
    if (detections.isNotEmpty) {
      buffer.writeln('🔍 Objects Detected:');
      for (final detection in detections) {
        final className = detection['class'] ?? 'Unknown';
        final confidence = (detection['confidence'] as num?)?.toStringAsFixed(2) ?? '0.00';
        buffer.writeln('  • $className (${(double.parse(confidence) * 100).toStringAsFixed(1)}% confidence)');
      }
      buffer.writeln();
    }

    // Soil analysis
    final soilAnalysis = results['soil_analysis'] as Map<String, dynamic>?;
    if (soilAnalysis != null) {
      buffer.writeln('🌱 Soil Analysis:');
      final soilType = soilAnalysis['soil_type'] ?? 'Unknown';
      final confidence = (soilAnalysis['confidence'] as num?)?.toStringAsFixed(2) ?? '0.00';
      final fertility = soilAnalysis['fertility'] ?? 'Unknown';
      final recommendation = soilAnalysis['recommendation'] ?? 'No recommendation';
      
      buffer.writeln('  • Type: $soilType');
      buffer.writeln('  • Confidence: ${(double.parse(confidence) * 100).toStringAsFixed(1)}%');
      buffer.writeln('  • Fertility: $fertility');
      buffer.writeln('  • Recommendation: $recommendation');
    }

    // Summary
    if (results.containsKey('summary')) {
      buffer.writeln();
      buffer.writeln('📊 Summary: ${results['summary']}');
    }

    // Add timestamp
    if (results.containsKey('timestamp')) {
      final timestamp = results['timestamp'];
      buffer.writeln();
      buffer.writeln('⏰ Analyzed at: ${DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt()).toString()}');
    }

    return buffer.toString();
  }

  // Get backend status
  Future<Map<String, dynamic>> getBackendStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Backend returned status ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Failed to connect to backend: $e'};
    }
  }
}
