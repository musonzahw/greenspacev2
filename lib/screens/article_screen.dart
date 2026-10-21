import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// For web support
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Conditional import for web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class ArticleScreen extends StatefulWidget {
  final String url;
  final String title;

  const ArticleScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // For web, we'll handle the URL differently
      _isLoading = false;
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    try {
      late final PlatformWebViewControllerCreationParams params;
      
      if (Platform.isIOS) {
        params = WebKitWebViewControllerCreationParams();
      } else if (Platform.isAndroid) {
        params = const PlatformWebViewControllerCreationParams();
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

      // Platform specific configurations
      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController)
          ..setMediaPlaybackRequiresUserGesture(false);
      }

      // Configure the WebView
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('WebView error: ${error.description}');
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: kIsWeb
          ? _buildWebFallback()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller != null
                  ? WebViewWidget(controller: _controller!)
                  : _buildErrorView(),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.inAppWebView : LaunchMode.externalApplication,
      );
    }
  }

  Widget _buildWebFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Opening article in browser...'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _launchURL(widget.url),
            child: const Text('Open Article'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Failed to load the article.'),
          Text('Please check your internet connection and try again.'),
        ],
      ),
    );
  }
}
