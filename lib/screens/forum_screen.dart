import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/forum_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ForumService _forumService = ForumService();

  File? _imageFile;
  bool _isLoading = true;
  bool _isDarkMode = true;
  bool _isPosting = false;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  List<Map<String, dynamic>> _messages = [];

  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPosts();
  }

  Future<void> _loadInitialPosts() async {
    if (_messages.isNotEmpty) return;
    
    try {
      setState(() => _isLoading = true);
      final posts = await _forumService.getForumPosts(
        page: 0,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      
      setState(() {
        _messages = posts;
        _currentPage = 1;
        _hasMore = posts.length == _pageSize;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    
    try {
      setState(() => _isLoading = true);
      
      final posts = await _forumService.getForumPosts(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;
      
      setState(() {
        if (posts.isEmpty) {
          _hasMore = false;
        } else {
          _messages.addAll(posts);
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more posts: ${e.toString()}')),
        );
      }
    }
  }

  void _onScroll() {
    if (!_isLoading &&
        _hasMore &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper method to get month name from month number
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Helper method to format time in 12-hour format
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Build a stat item widget (likes, comments, etc.)
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          count > 0 ? count.toString() : '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  // Build an action button for the post
  // Build an action button for the post
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a placeholder widget for coming soon features
  Widget _buildComingSoonPlaceholder(String message, {TextStyle? style}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showPostDetails(BuildContext context, Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Format post date
    final createdAt = post['created_at'] != null 
        ? DateTime.parse(post['created_at']).toLocal() 
        : DateTime.now();
    final formattedDate = '${_getMonthName(createdAt.month)} ${createdAt.day}, ${createdAt.year} • ${_formatTime(createdAt)}';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Reduced from 0.9 to make it more compact
          minChildSize: 0.4,    // Reduced from 0.5
          maxChildSize: 0.9,    // Slightly reduced from 0.95
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  
                  // Header with close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 8), // For balance
                        Text(
                          'Post',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withOpacity(0.7)),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User info row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User avatar
                              Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 24,
                                  color: colorScheme.primary,
                                ),
                              ),
                              
                              // User name and date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['user_name'] ?? 'Anonymous',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedDate,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // More options button
                              IconButton(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  size: 22,
                                ),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Post content
                          if (post['title']?.isNotEmpty == true) ...[
                            Text(
                              post['title'],
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          if (post['content']?.isNotEmpty == true) ...[
                            Text(
                              post['content'],
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Image if available
                          if (post['image_url'] != null && (post['image_url'] as String).isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  post['image_url'],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: colorScheme.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_rounded,
                                            size: 40,
                                            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Couldn\'t load image',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          // Action buttons with counts
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: colorScheme.surfaceVariant, width: 1),
                                bottom: BorderSide(color: colorScheme.surfaceVariant, width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.thumb_up_outlined,
                                  label: likesCount > 0 ? likesCount.toString() : 'Like',
                                  onTap: () {},
                                ),
                                _buildActionButton(
                                  icon: Icons.comment_outlined,
                                  label: commentsCount > 0 ? commentsCount.toString() : 'Comment',
                                  onTap: () {},
                                ),
                                _buildActionButton(
                                  icon: Icons.share_outlined,
                                  label: 'Share',
                                  onTap: () => _sharePost(post),
                                ),
                                _buildActionButton(
                                  icon: Icons.bookmark_border_rounded,
                                  label: 'Save',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                          
                          // Comments section header
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              'Comments',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          
                          // Reply input field
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                // User avatar
                                Container(
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                
                                // Input field
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Write a comment...',
                                      hintStyle: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                      isDense: true,
                                    ),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                
                                // Emoji button
                                IconButton(
                                  icon: Icon(
                                    Icons.emoji_emotions_outlined,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    size: 22,
                                  ),
                                  onPressed: () {},
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          
                          // Comments list placeholder
                          _buildComingSoonPlaceholder(
                            'Comments will appear here',
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildPostActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    int count = 0,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                count.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              const SizedBox(width: 6),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _buildComingSoonPlaceholder is defined above with the style parameter

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await _forumService.createPost(
        title: _titleController.text,
        content: _contentController.text,
        imageFile: _imageFile,
      );

      // Clear form and refresh posts
      _titleController.clear();
      _contentController.clear();
      setState(() => _imageFile = null);

      // Reset and reload posts
      setState(() {
        _messages = [];
        _currentPage = 0;
        _hasMore = true;
      });
      await _loadInitialPosts();

      if (mounted) {
        Navigator.of(context).pop(); // Close the post creation dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _showPostOptions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () {
              Navigator.pop(context);
              _editPost(post);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(post);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await _forumService.deletePost(post['id']);
        
        if (mounted) {
          setState(() {
            _messages.removeWhere((p) => p['id'] == post['id']);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    _titleController.text = post['title'] ?? '';
    _contentController.text = post['content'] ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Post'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 16),
                  if (post['image_url'] != null && _imageFile == null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post['image_url'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _imageFile = File(''); // Empty file to indicate removal
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_imageFile != null && _imageFile!.path.isNotEmpty)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: () => _pickImage(ImageSource.gallery),
                        tooltip: 'Change image',
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () => _pickImage(ImageSource.camera),
                        tooltip: 'Take a new photo',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isPosting ? null : () {
                  _imageFile = null;
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isPosting ? null : () => _updatePost(post['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6F5C),
                  foregroundColor: Colors.white,
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updatePost(String postId) async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')),
        );
      }
      return;
    }

    setState(() => _isPosting = true);

    try {
      await _forumService.updatePost(
        postId: postId,
        title: _titleController.text,
        content: _contentController.text,
        imageFile: _imageFile,
        removeImage: _imageFile != null && _imageFile!.path.isEmpty,
      );

      // Clear form and refresh posts
      _titleController.clear();
      _contentController.clear();
      setState(() => _imageFile = null);

      // Reset and reload posts
      setState(() {
        _messages = [];
        _currentPage = 0;
        _hasMore = true;
      });

      await _loadInitialPosts();

      if (mounted) {
        Navigator.of(context).pop(); // Close the edit dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _showNewMessageForm() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Forum Post',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter a title for your post',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 1,
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),

                    // Content Field
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        hintText: 'What would you like to share?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 5,
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 16),

                    // Image Upload
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Image (Optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.2),
                                width: 1,
                              ),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageFile == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 40,
                                        color: Theme.of(context).hintColor,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add an image',
                                        style: GoogleFonts.poppins(
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        if (_imageFile != null)
                          TextButton.icon(
                            onPressed: () => setState(() => _imageFile = null),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: Text(
                              'Remove image',
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Post Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isPosting ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'POST TO FORUM',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
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
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search forum...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
              onSubmitted: (value) {
                // TODO: Implement search submission
              },
            ),
          ),
          Expanded(
            child: _isInitialLoad && _messages.isEmpty
                ? _buildShimmerLoading()
                : _messages.isEmpty
                    ? const Center(child: Text('No posts yet. Be the first to post!'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            _messages = [];
                            _currentPage = 0;
                            _hasMore = true;
                            _isInitialLoad = true;
                          });
                          await _loadInitialPosts();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _messages.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _messages.length) {
                              return _buildLoadingIndicator();
                            }
                            final message = _messages[index];
                            return _buildMessageCard(context, message);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildPostActions(BuildContext context, Map<String, dynamic> message, bool isExpanded) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isExpanded ? 1.0 : 0.0,
      child: Visibility(
        visible: isExpanded,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.thumb_up_outlined,
                label: 'Like',
                onTap: () {
                  // Handle like action
                },
              ),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: 'Comment',
                onTap: () {
                  _showPostDetails(context, message);
                },
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  _sharePost(message);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, Map<String, dynamic> message) {
    final createdAt = message['created_at'] != null
        ? DateTime.parse(message['created_at'] as String)
        : DateTime.now();
    final timeAgo = _formatTimeAgo(createdAt);
    final userAvatar = message['user_avatar']?.toString().isNotEmpty == true
        ? message['user_avatar'].toString()
        : '👤';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          final isExpanded = message['_isExpanded'] as bool? ?? false;
          
          return Column(
            children: [
              // Collapsed header (always visible)
              InkWell(
                onTap: () {
                  setState(() {
                    message['_isExpanded'] = !isExpanded;
                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar
                      CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          userAvatar,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    message['user_name'] as String? ?? 'Anonymous',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Three dot menu for post owner (moved to the right)
                                if (message['user_id'] == _forumService.userId) // Only show for current user's posts
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editPost(message);
                                      } else if (value == 'delete') {
                                        _showDeleteConfirmation(message);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(width: 1), // Reduced spacing
                                // Eye icon for viewing post details
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    _showPostDetails(context, message);
                                  },
                                  tooltip: 'View post details',
                                ),
                              ],
                            ),
                            Text(
                              message['title'] as String? ?? 'Tap to view post',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable content
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post title (only show in expanded view if it exists)
                      if (message['title'] != null && (message['title'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            message['title'] as String,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ),

                      // Post content
                      Text(
                        message['content'] as String? ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      // Image if available
                      if (message['image_url'] != null && (message['image_url'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              message['image_url'] as String,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Action buttons (only visible when expanded)
              if (isExpanded) _buildPostActions(context, message, isExpanded),

              // Comment section
              _buildCommentSection(context, message),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCommentList(List<Map<String, dynamic>> comments) {
    return comments.take(2).map<Widget>((comment) {
      final content = comment['content'] as String? ?? '';
      final userName = comment['user_name'] as String? ?? 'Anonymous';
      final createdAt = comment['created_at'] as String?;
      final avatar = comment['user_avatar']?.toString().isNotEmpty == true
          ? comment['user_avatar'].toString()
          : '👤';

      final timeAgo = _formatTimeAgo(
        createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      );

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: Text(
                avatar,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCommentSection(BuildContext context, Map<String, dynamic> message) {
    final comments = (message['recent_comments'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final replyCount = message['reply_count'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comments.isNotEmpty) ..._buildCommentList(comments),
        if (replyCount > 0) _buildViewAllComments(context, message, replyCount),
        _buildCommentInput(context, message),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context, Map<String, dynamic> message) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Add a comment...',
          hintStyle: GoogleFonts.poppins(
            color: Theme.of(context).hintColor,
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, size: 20),
            onPressed: () {
              // Handle send comment
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 13),
        onTap: () {
          _showPostDetails(context, message);
        },
      ),
    );
  }

  // Edit post - Implementation kept from earlier in the file

  // View all comments button
  Widget _buildViewAllComments(BuildContext context, Map<String, dynamic> message, int count) {
    return GestureDetector(
      onTap: () => _showPostDetails(context, message),
      child: Text(
        'View all $count ${count == 1 ? 'comment' : 'comments'}',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    try {
      final text = '${post['title'] ?? 'Check out this post'}\n\n${post['content'] ?? ''}';
      
      // Using the share_plus package to share content
      await Share.share(
        text,
        subject: (post['title'] as String?) ?? 'Shared from Greenspace',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing post: ${e.toString()}')),
        );
      }
    }
  }



  Widget _buildFloatingActionButton() {
    return Container(
      margin: EdgeInsets.only(bottom: 80.0), // Add extra space above bottom navigation
      child: FloatingActionButton(
        onPressed: () {
          // Reset form when opening the create dialog
          _titleController.clear();
          _contentController.clear();
          _imageFile = null;
          _showNewMessageForm();
        },
        backgroundColor: const Color(0xFF1E6F5C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;
    final shimmerColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
    
    return ListView.builder(
      itemCount: 5, // Number of shimmer items to show
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with avatar and user info
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            color: shimmerColor,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 12,
                            color: shimmerColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Post content
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: shimmerColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: shimmerColor,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 14,
                    color: shimmerColor,
                  ),
                  const SizedBox(height: 16),
                  // Image placeholder
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(
                    height: 1,
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildShimmerActionButton(shimmerColor),
                      _buildShimmerActionButton(shimmerColor),
                      _buildShimmerActionButton(shimmerColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerActionButton(Color color) {
    return Container(
      width: 60,
      height: 20,
      color: color,
    );
  }
}