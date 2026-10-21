import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/green_guardian_service.dart';
import '../models/green_guardian_report.dart';
import 'green_guardian_reports_screen.dart';

class GreenGuardianScreen extends StatefulWidget {
  final bool showReportsTab;
  
  const GreenGuardianScreen({
    super.key,
    this.showReportsTab = false,
  });

  @override
  State<GreenGuardianScreen> createState() => _GreenGuardianScreenState();
}

class _GreenGuardianScreenState extends State<GreenGuardianScreen> {
  // Form and Controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Services and State
  final _greenGuardianService = GreenGuardianService();
  final _supabase = Supabase.instance.client;
  
  String? _selectedCategory;
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'pollution', 'name': 'Pollution', 'icon': FontAwesomeIcons.smog},
    {'id': 'littering', 'name': 'Littering', 'icon': FontAwesomeIcons.trash},
    {'id': 'deforestation', 'name': 'Deforestation', 'icon': FontAwesomeIcons.tree},
    {'id': 'water', 'name': 'Water Contamination', 'icon': FontAwesomeIcons.water},
    {'id': 'air', 'name': 'Air Pollution', 'icon': FontAwesomeIcons.wind},
    {'id': 'wildlife', 'name': 'Wildlife Threat', 'icon': FontAwesomeIcons.paw},
  ];

  Future<void> _pickImage() async {
    try {
      print('🖼️ Picking image...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (pickedFile == null) {
        print('❌ No image selected');
        return;
      }

      print('✅ Image selected: ${pickedFile.path}');
      
      // Create a new file in the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'report_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      print('💾 Image saved to: ${savedImage.path}');
      
      if (mounted) {
        setState(() {
          _selectedImage = savedImage;
        });
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    print('\n=== SUBMIT BUTTON PRESSED ===');
    print('🔍 Starting form validation...');
    
    // First, validate all form fields
    bool isValid = _formKey.currentState!.validate();
    print('✅ Form fields validation result: $isValid');
    
    // Check each field's validation
    if (_titleController.text.trim().isEmpty) {
      print('❌ Title is empty');
    } else {
      print('✅ Title: ${_titleController.text}');
    }
    
    if (_locationController.text.trim().isEmpty) {
      print('❌ Location is empty');
    } else {
      print('✅ Location: ${_locationController.text}');
    }
    
    if (_descriptionController.text.trim().length < 10) {
      print('❌ Description is too short (${_descriptionController.text.length} characters)');
    } else {
      print('✅ Description length: ${_descriptionController.text.length} characters');
    }
    
    // Check if category is selected
    if (_selectedCategory == null) {
      print('❌ No category selected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      // Don't return here, let the form show all validation errors
      isValid = false;
    } else {
      print('✅ Category selected: $_selectedCategory');
    }
    
    if (!isValid) {
      print('❌ Form validation failed. Please check the errors above.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    print('✅ All validations passed. Proceeding with form submission...');

    // Check if user is authenticated
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('❌ User not authenticated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to submit a report'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    print('👤 User authenticated. User ID: ${user.id}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n📤 Preparing to submit report...');
      print('📝 Title: ${_titleController.text}');
      print('📄 Description length: ${_descriptionController.text.length} characters');
      print('🏷️ Category: $_selectedCategory');
      print('📍 Location: ${_locationController.text}');
      print('👤 User ID: ${user.id}');
      print('🖼️ Image selected: ${_selectedImage != null}');
      
      // Call the service to submit the report
      print('\n🚀 Calling _greenGuardianService.submitReport()...');
      final report = await _greenGuardianService.submitReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        locationText: _locationController.text.trim(),
        image: _selectedImage,
        userId: user.id,
      );

      print('\n🎉 Report submitted successfully!');
      print('📊 Report ID: ${report.id}');
      print('📅 Created at: ${report.createdAt}');
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // Reset form
        print('\n🔄 Resetting form...');
        _formKey.currentState?.reset();
        setState(() {
          _selectedImage = null;
          _selectedCategory = null;
          _isLoading = false;
        });
        print('✅ Form reset complete');
      }
    } catch (e, stackTrace) {
      print('\n❌❌❌ ERROR SUBMITTING REPORT ❌❌❌');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace:');
      print(stackTrace);
      
      if (mounted) {
        // Show detailed error message
        final errorMessage = e.toString();
        print('\n📢 Showing error to user: $errorMessage');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.length > 100 
                ? 'Failed to submit report. Please try again.' 
                : 'Failed: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GreenGuardianReportsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Define colors that adapt to theme
    final cardColor = isDark ? colorScheme.surface : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final iconColor = colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: isDark ? colorScheme.background : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Report an Issue',
          style: TextStyle(color: colorScheme.onBackground),
        ),
        backgroundColor: isDark ? colorScheme.surface : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(Icons.list_alt, color: colorScheme.onSurface),
            onPressed: _navigateToReports,
            tooltip: 'View My Reports',
          ),
        ],
      ),
      // Add bottom padding to account for the navigation bar
      bottomNavigationBar: Container(
        height: kBottomNavigationBarHeight,
        color: isDark ? colorScheme.surface : Colors.white,
        child: Container(
          height: 1,
          color: borderColor.withOpacity(0.5),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    Text(
                      'Title *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          if (!isDark) BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter a title for your report',
                          hintStyle: TextStyle(color: hintColor, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(height: 0.8),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title for your report';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Category Selection
                    Text(
                      'Category *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          if (!isDark) BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category['id'];
                              
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = category['id'] as String;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary.withOpacity(0.1)
                                          : (isDark ? colorScheme.surface : Colors.grey[100]),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FaIcon(
                                          category['icon'] as IconData,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                          size: 22,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          category['name'] as String,
                                          style: TextStyle(
                                            color: isSelected
                                                ? colorScheme.primary
                                                : (isDark ? Colors.grey[300] : Colors.grey[800]),
                                            fontSize: 11.5,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_selectedCategory == null && _formKey.currentState?.validate() == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Please select a category',
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Location
                    Text(
                      'Location *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          if (!isDark) BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _locationController,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter the location of the issue',
                          hintStyle: TextStyle(color: hintColor, fontSize: 15),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: hintColor,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(height: 0.8),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the location of the issue';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Photo Upload
                    Text(
                      'Add Photo (Optional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? colorScheme.surface : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          boxShadow: [
                            if (!isDark) BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 32,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to add a photo',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'JPEG, PNG (Max 5MB)',
                                    style: TextStyle(
                                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '1 photo selected',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                'Change',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      'Description *',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                        boxShadow: [
                          if (!isDark) BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Provide details about the issue...',
                          hintStyle: TextStyle(
                            color: hintColor,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          errorMaxLines: 2,
                          errorStyle: const TextStyle(height: 0.8),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a description of the issue';
                          }
                          if (value.trim().length < 10) {
                            return 'Description should be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Submit Button - Fixed at the bottom with bottom padding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading 
                    ? null 
                    : () {
                        print('Button pressed, calling _submitReport');
                        _submitReport();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SUBMIT REPORT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
