import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static String? _apiKey;

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    _apiKey = dotenv.env['NEWS_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('NewsAPI key not found in .env file');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchEnvironmentalNews() async {
    if (_apiKey == null) {
      await initialize();
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/everything?q=environment OR climate OR sustainability&sortBy=publishedAt&language=en&apiKey=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'ok') {
          final List<dynamic> articles = data['articles'];
          return articles.map((article) => _formatArticle(article)).toList();
        } else {
          throw Exception('Failed to load news: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  static Map<String, dynamic> _formatArticle(Map<String, dynamic> article) {
    return {
      'title': article['title'] ?? 'No title',
      'summary': article['description'] ?? 'No description available',
      'date': _formatDate(article['publishedAt']),
      'source': article['source']['name'] ?? 'Unknown source',
      'imageUrl': article['urlToImage'] ?? 'https://via.placeholder.com/800x400?text=No+Image',
      'url': article['url'],
      'content': article['content'] ?? 'No content available',
    };
  }

  static String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
