import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/green_guardian_service.dart';
import '../models/green_guardian_report.dart';
import 'report_edit_screen.dart';

class GreenGuardianReportsScreen extends StatefulWidget {
  const GreenGuardianReportsScreen({super.key});

  @override
  State<GreenGuardianReportsScreen> createState() => _GreenGuardianReportsScreenState();
}

class _GreenGuardianReportsScreenState extends State<GreenGuardianReportsScreen> {
  final GreenGuardianService _greenGuardianService = GreenGuardianService();
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  List<GreenGuardianReport> _reports = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final reports = await _greenGuardianService.getUserReports(user.id);
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reports: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEditReport(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportEditScreen(
          reportId: reportId,
          isNewReport: false,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from edit screen
      if (mounted) {
        _loadReports();
      }
    });
  }
  
  void _showReportDetails(BuildContext context, GreenGuardianReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (report.mediaUrls?.isNotEmpty == true) ...[
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: report.mediaUrls!.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          report.mediaUrls![index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Container(
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.broken_image, size: 50)),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                report.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.category, report.category),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_on, report.locationText),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today,
                'Submitted on: ${_formatDate(report.createdAt)}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.info_outline,
                'Status: ${report.status.replaceAll('_', ' ').toUpperCase()}',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the bottom sheet
                    _navigateToEditReport(report.id);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('EDIT REPORT'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  // Handle edit action from the bottom sheet
  void _handleEditAction(String reportId) {
    Navigator.pop(context); // Close the bottom sheet
    _navigateToEditReport(reportId);
  }

  Future<void> _showReportOptions(
      BuildContext context, GreenGuardianReport report) async {
    // Show bottom sheet with options
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Report'),
              onTap: () => Navigator.pop(context, 'view'),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Report'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
          ],
        ),
      ),
    );

    // Check if widget is still mounted
    if (!mounted) return;
    
    // Handle view action
    if (result == 'view' && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) => AlertDialog(
          title: Text(report.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (report.mediaUrls?.isNotEmpty == true) ...[
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: report.mediaUrls!.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Image.network(
                          report.mediaUrls![index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 100),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  report.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.category, report.category),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on, report.locationText),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Submitted on: ${_formatDate(report.createdAt)}',
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.info_outline,
                  'Status: ${report.status.replaceAll('_', ' ').toUpperCase()}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
    } else if (result == 'edit') {
      // Handle edit action
      _navigateToEditReport(report.id);
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportItem(GreenGuardianReport report) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Stack(
        children: [
          // Main content
          InkWell(
            onTap: () => _showReportOptions(context, report),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Description
                  const SizedBox(height: 8),
                  Text(
                    report.description.length > 100
                        ? '${report.description.substring(0, 100)}...'
                        : report.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  
                  // Category and location row
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          report.category,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          report.locationText,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  // Media gallery if available
                  if (report.mediaUrls?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: report.mediaUrls?.length ?? 0,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Image.network(
                              report.mediaUrls![index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Submission date
                  const SizedBox(height: 8),
                  Text(
                    'Submitted on: ${_formatDate(report.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          // Eye icon for quick view - positioned below the status badge
          Positioned(
            top: 48,  // Moved down further from 32 to position below the status badge
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showReportDetails(context, report),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_red_eye,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReports,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reports.isEmpty
                  ? const Center(
                      child: Text('No reports found. Submit a report to see it here!'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          return _buildReportItem(_reports[index]);
                        },
                      ),
                    ),
    );
  }
}
