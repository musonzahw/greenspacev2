import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_analysis_service.dart';

class ImageRecognitionScreen extends StatefulWidget {
  const ImageRecognitionScreen({Key? key}) : super(key: key);

  @override
  State<ImageRecognitionScreen> createState() => _ImageRecognitionScreenState();
}

class _ImageRecognitionScreenState extends State<ImageRecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String? _analysisResult;
  Map<String, dynamic>? _detectionResults;
  Timer? _analysisTimer;
  final ImageAnalysisService _analysisService = ImageAnalysisService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _analysisTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera: $e')),
      );
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = 'Capturing image...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      await _analyzeImage(File(image.path));
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _analysisResult = 'Error capturing image: $e';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _isAnalyzing = true;
        _analysisResult = 'Analyzing image...';
      });
      await _analyzeImage(File(image.path));
    }
  }

  Future<void> _analyzeImage(File imageFile) async {
    try {
      final results = await _analysisService.analyzeImage(imageFile);
      setState(() {
        _detectionResults = results;
        _analysisResult = _analysisService.formatAnalysisResults(results);
      });
    } catch (e) {
      print('Error analyzing image: $e');
      setState(() {
        _analysisResult = 'Error analyzing image: $e';
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  
  void _toggleRealTimeAnalysis() {
    if (_analysisTimer != null && _analysisTimer!.isActive) {
      _analysisTimer?.cancel();
      setState(() {
        _analysisResult = 'Real-time analysis stopped';
      });
    } else {
      _analysisTimer = Timer.periodic(Duration(seconds: 3), (timer) {
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          _captureFrameForRealTimeAnalysis();
        }
      });
      setState(() {
        _analysisResult = 'Real-time analysis started...';
      });
    }
  }

  Future<void> _captureFrameForRealTimeAnalysis() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final results = await _analysisService.analyzeFrame('data:image/jpeg;base64,$base64Image');
      if (mounted) {
        setState(() {
          _detectionResults = results;
          _analysisResult = _analysisService.formatAnalysisResults(results);
        });
      }
    } catch (e) {
      print('Error in real-time analysis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Recognition'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_analysisTimer?.isActive == true ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleRealTimeAnalysis,
            tooltip: _analysisTimer?.isActive == true ? 'Stop Real-time' : 'Start Real-time',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: _buildCameraPreview(),
            ),
          ),
          
          // Analysis results
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Results:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _isAnalyzing
                          ? Center(child: CircularProgressIndicator())
                          : Text(
                              _analysisResult ?? 'No analysis yet',
                              style: TextStyle(fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Control buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: Icon(Icons.photo_library),
              label: Text('Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _captureAndAnalyze,
              icon: Icon(Icons.camera_alt),
              label: Text('Analyze'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(
        child: Text(
          'Camera not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }
}
