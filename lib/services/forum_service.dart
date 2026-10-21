import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ForumService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _storage = Supabase.instance.client.storage.from('forum_images');
  
  // Get current user ID
  String? get userId => _supabase.auth.currentUser?.id;

  // Get all forum posts with pagination
  Future<List<Map<String, dynamic>>> getForumPosts({int page = 0, int pageSize = 10}) async {
    final response = await _supabase
        .from('forum_posts')
        .select('*')
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Get a single post by ID
  Future<Map<String, dynamic>> getPostById(String postId) async {
    final response = await _supabase
        .from('forum_posts')
        .select('*')
        .eq('id', postId)
        .single();
    
    return response;
  }

  // Create a new post
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    File? imageFile,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Upload image if provided
    String? imageUrl;
    if (imageFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      await _storage.upload(fileName, imageFile);
      imageUrl = _storage.getPublicUrl(fileName);
    }

    final response = await _supabase
        .from('forum_posts')
        .insert({
          'user_id': userId,
          'user_name': _supabase.auth.currentUser?.email?.split('@')[0] ?? 'Anonymous',
          'user_avatar': '👤', // Default avatar, can be customized
          'title': title,
          'content': content,
          'image_url': imageUrl,
        })
        .select()
        .single();

    return response;
  }

  // Update a post
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required String title,
    required String content,
    File? imageFile,
    bool removeImage = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    String? imageUrl;
    if (imageFile != null) {
      // Upload new image
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      await _storage.upload(fileName, imageFile);
      imageUrl = _storage.getPublicUrl(fileName);
    } else if (removeImage) {
      imageUrl = null;
    }

    final updates = {
      'title': title,
      'content': content,
      if (imageFile != null || removeImage) 'image_url': imageUrl,
    };

    final response = await _supabase
        .from('forum_posts')
        .update(updates)
        .eq('id', postId)
        .eq('user_id', userId)
        .select()
        .single();

    return response;
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // First get the post to check ownership and get image URL
    final post = await _supabase
        .from('forum_posts')
        .select('*')
        .eq('id', postId)
        .single();

    if (post['user_id'] != userId) {
      throw Exception('Not authorized to delete this post');
    }

    // Delete the post
    await _supabase
        .from('forum_posts')
        .delete()
        .eq('id', postId);

    // Delete the associated image if it exists
    if (post['image_url'] != null) {
      try {
        final imagePath = post['image_url'].split('/').last;
        await _storage.remove([imagePath]);
      } catch (e) {
        // Log error but don't fail the operation
        print('Error deleting image: $e');
      }
    }
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Check if the user already liked the post
    final response = await _supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', currentUserId);

    if (response.isNotEmpty) {
      // Unlike
      await _supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUserId);
    } else {
      // Like
      await _supabase
          .from('post_likes')
          .insert({
            'post_id': postId,
            'user_id': currentUserId,
          });
    }
  }

  // Get like count for a post
  Future<int> getLikeCount(String postId) async {
    final response = await _supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId);
    
    return response.length;
  }

  // Check if current user liked a post
  Future<bool> isPostLikedByUser(String postId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final response = await _supabase
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', currentUserId);
    
    return response.isNotEmpty;
  }
}
