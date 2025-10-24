import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

/// Simple direct AI service - no queue, direct processing
class AiDirectService {
  final SupabaseClient _client = Supabase.instance.client;
  
  /// Generate personalized cover directly
  Future<String> generatePersonalizedCover({
    required String bookId,
    required String bookName,
    required String childImageUrl,
    required String childName,
    String? childImageBase64,
    String? childImageMime,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in');
      }

      debugPrint('[AiDirectService] Starting direct generation...');
      debugPrint('[AiDirectService] Child URL: $childImageUrl');
      debugPrint('[AiDirectService] Child Name: $childName');

      // Prepare request body with child image only
      final requestBody = {
        'bookId': bookId,
        'bookName': bookName,
        'childImageUrl': childImageUrl,
        'childName': childName,
        'userId': user.id,
      };

      debugPrint('[AiDirectService] Request body: $requestBody');

      // Call Supabase Edge Function directly
      final response = await _client.functions.invoke(
        'smooth-endpoint',
        body: requestBody,
      );

      debugPrint('[AiDirectService] Raw response: ${response.toString()}');
      debugPrint('[AiDirectService] Response status: ${response.status}');
      debugPrint('[AiDirectService] Response data: ${response.data}');

      if (response.status != 200) {
        final errorMsg = response.data != null ? response.data.toString() : 'Unknown error';
        throw Exception('Function call failed with status ${response.status}: $errorMsg');
      }

      if (response.data == null) {
        throw Exception('Function returned null data');
      }

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Function returned invalid data format');
      }

      if (data['success'] != true) {
        final errorMsg = data['error'] ?? 'Unknown error from function';
        throw Exception('Function reported error: $errorMsg');
      }

      // Check if we have base64 image data
      final generatedImageBase64 = data['generated_image_base64'] as String?;
      if (generatedImageBase64 != null && generatedImageBase64.isNotEmpty) {
        // Return base64 data URL that Flutter can handle
        final dataUrl = 'data:image/jpeg;base64,$generatedImageBase64';
        debugPrint('[AiDirectService] Generated image as base64 data URL');
        return dataUrl;
      }

      // Fallback to URL if available
      final generatedImageUrl = data['generated_image_url'] as String?;
      if (generatedImageUrl != null && generatedImageUrl.isNotEmpty) {
        debugPrint('[AiDirectService] Generated image URL: $generatedImageUrl');
        return generatedImageUrl;
      }

      throw Exception('Function did not return image data or URL');

    } catch (e) {
      debugPrint('[AiDirectService] Detailed error: $e');
      debugPrint('[AiDirectService] Error type: ${e.runtimeType}');
      rethrow;
    }
  }
}
