import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SoilScanScreen extends StatefulWidget {
  const SoilScanScreen({super.key});

  @override
  State<SoilScanScreen> createState() => _SoilScanScreenState();
}

class _SoilScanScreenState extends State<SoilScanScreen> {
  CameraController? _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  String _resultText = 'Point camera at soil to analyze';
  double _confidence = 0.0;
  File? _capturedImage;
  bool _showResult = false;

  // Sample soil types - this would come from a backend service in production
  final List<Map<String, dynamic>> _soilTypes = [
    {
      'name': 'Loamy Soil',
      'description': 'Ideal for most plants, good water retention and drainage',
      'color': Color(0xFF8B4513),
      'suitableFor': ['Vegetables', 'Fruits', 'Flowers', 'Shrubs'],
      'ph': '6.0 - 7.0',
      'improvements': 'Add organic matter annually',
    },
    {
      'name': 'Sandy Soil',
      'description': 'Drains quickly, warms up fast in spring',
      'color': Color(0xFFF4A460),
      'suitableFor': ['Carrots', 'Potatoes', 'Lettuce', 'Strawberries'],
      'ph': '5.5 - 6.5',
      'improvements': 'Add organic matter to improve water retention',
    },
    {
      'name': 'Clay Soil',
      'description': 'Heavy soil that holds water, warms slowly in spring',
      'color': Color(0xFF8B4513).withRed(139),
      'suitableFor': ['Fruit Trees', 'Shrubs', 'Perennials'],
      'ph': '5.5 - 7.0',
      'improvements': 'Add sand and organic matter to improve drainage',
    },
    {
      'name': 'Silty Soil',
      'description': 'Fertile soil that holds moisture, has a soft texture',
      'color': Color(0xFFC0C0C0),
      'suitableFor': ['Grasses', 'Perennials', 'Shrubs', 'Vines'],
      'ph': '6.0 - 7.5',
      'improvements': 'Add compost to prevent compaction',
    },
  ];
  
  final Random _random = Random();
  
  // Simulate soil analysis (in a real app, this would use ML model)
  Future<Map<String, dynamic>> _analyzeSoil(File image) async {
    // Simulate network/processing delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Return a random soil type for demo purposes
    return _soilTypes[_random.nextInt(_soilTypes.length)];
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      await _initializeControllerFuture;
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error initializing camera. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized) return;

    try {
      setState(() {
        _isAnalyzing = true;
        _resultText = 'Analyzing soil...';
      });

      // Take the picture in a try / catch block. If anything goes wrong,
      // catch the error.
      final XFile image = await _cameraController!.takePicture();
      
      // Save the picture to the device
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'soil_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      // Analyze the soil (simulated for now)
      final soilType = await _analyzeSoil(savedImage);
      
      if (mounted) {
        setState(() {
          _capturedImage = savedImage;
          _resultText = soilType['name'];
          _confidence = 0.8 + _random.nextDouble() * 0.2; // 80-100% confidence
          _showResult = true;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error taking picture. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isAnalyzing = false;
          _resultText = 'Error. Please try again.';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _isAnalyzing = true;
        _resultText = 'Analyzing soil...';
        _showResult = false;
      });
      
      // Save the picked image
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'soil_${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedFile.path)}';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      // Analyze the soil (simulated for now)
      final soilType = await _analyzeSoil(savedImage);
      
      if (mounted) {
        setState(() {
          _capturedImage = savedImage;
          _resultText = soilType['name'];
          _confidence = 0.8 + _random.nextDouble() * 0.2; // 80-100% confidence
          _showResult = true;
          _isAnalyzing = false;
        });
      }
    }
  }

  void _resetCamera() {
    setState(() {
      _showResult = false;
      _capturedImage = null;
      _resultText = 'Point camera at soil to analyze';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Scan'),
        actions: [
          if (_capturedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetCamera,
              tooltip: 'Scan again',
            ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview or Captured Image
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: _showResult && _capturedImage != null
                    ? Image.file(
                        _capturedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : _isCameraInitialized
                        ? CameraPreview(_cameraController!)
                        : const CircularProgressIndicator(),
              ),
            ),
          ),
          
          // Analysis Result or Instructions
          Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            color: theme.colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resultText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_confidence > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Soil Details (shown when analysis is complete)
          if (_showResult && _resultText != 'Point camera at soil to analyze')
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildSoilDetails(),
              ),
            ),
        ],
      ),
      
      // Camera Controls
      bottomNavigationBar: _showResult
          ? null
          : BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: _isAnalyzing ? null : _pickImage,
                    tooltip: 'Choose from gallery',
                  ),
                  IconButton(
                    icon: Icon(
                      _isAnalyzing ? Icons.hourglass_top : Icons.camera_alt,
                      size: 32.0,
                    ),
                    onPressed: _isAnalyzing ? null : _takePicture,
                    tooltip: 'Take picture',
                  ),
                  const SizedBox(width: 48), // Spacer for centering
                ],
              ),
            ),
    );
  }
  
  Widget _buildSoilDetails() {
    final theme = Theme.of(context);
    final soilType = _soilTypes.firstWhere(
      (soil) => soil['name'] == _resultText,
      orElse: () => _soilTypes[0],
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Soil Type Card
        Card(
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: soilType['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      soilType['name'],
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  soilType['description'],
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Soil Properties
        Text(
          'Soil Properties',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildPropertyRow('pH Level', soilType['ph']),
        _buildPropertyRow('Texture', soilType['name'].replaceAll(' Soil', '')),
        _buildPropertyRow('Drainage', _getDrainageInfo(soilType['name'])),
        
        const SizedBox(height: 16),
        
        // Suitable For
        Text(
          'Suitable For',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: (soilType['suitableFor'] as List<dynamic>).map<Widget>((plant) {
            return Chip(
              label: Text(plant),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Improvement Tips
        Text(
          'Improvement Tips',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(soilType['improvements']),
        
        const SizedBox(height: 16),
        
        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Save the soil analysis
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Soil analysis saved to your profile')),
              );
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('Save Analysis'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDrainageInfo(String soilType) {
    if (soilType.contains('Sandy')) return 'Fast';
    if (soilType.contains('Clay')) return 'Slow';
    if (soilType.contains('Loamy')) return 'Good';
    if (soilType.contains('Silty')) return 'Moderate';
    return 'Varies';
  }
}
