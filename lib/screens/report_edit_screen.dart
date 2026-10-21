import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/green_guardian_service.dart';
import '../models/green_guardian_report.dart';

class ReportEditScreen extends StatefulWidget {
  final String reportId;
  final bool isNewReport;

  const ReportEditScreen({
    super.key,
    required this.reportId,
    this.isNewReport = false,
  });

  @override
  State<ReportEditScreen> createState() => _ReportEditScreenState();
}

class _ReportEditScreenState extends State<ReportEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  final GreenGuardianService _service = GreenGuardianService();
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedCategory;
  File? _selectedImage;
  String? _imageUrl;
  
  final List<String> _categories = [
    'Littering',
    'Illegal Dumping',
    'Recycling Issues',
    'Hazardous Waste',
    'Pollution',
    'Other',
  ];
  
  // Ensure the selected category is in the categories list
  String? _getValidCategory(String? category) {
    if (category == null) return null;
    return _categories.contains(category) ? category : 'Other';
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isNewReport) {
      _loadReport();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    
    try {
      final report = await _service.getReportById(widget.reportId);
      
      if (!mounted) return;
      
      setState(() {
        _titleController.text = report.title;
        _descriptionController.text = report.description;
        _locationController.text = report.locationText;
        _selectedCategory = report.category;
        _imageUrl = report.mediaUrls?.isNotEmpty == true ? report.mediaUrls!.first : null;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageUrl = null; // Clear any existing image URL
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to submit a report')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _service.updateReport(
        reportId: widget.reportId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        locationText: _locationController.text.trim(),
        newImage: _selectedImage,
        userId: user.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully!')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewReport ? 'New Report' : 'Edit Report'),
        actions: [
          if (!widget.isNewReport)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                // TODO: Implement delete functionality
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Report'),
                    content: const Text(
                        'Are you sure you want to delete this report? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement delete
                          Navigator.pop(context);
                          Navigator.pop(context, true); // Return success
                        },
                        child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : _imageUrl != null
                        ? Image.network(_imageUrl!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Add Photo'),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _getValidCategory(_selectedCategory),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'Please enter a location' : null,
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('UPDATE REPORT'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
