import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../services/supabase_auth_service.dart';

class PDFUploadService {
  static const String bucketName = 'notesheet-pdfs';
  
  /// Upload a PDF file to Supabase storage
  /// Returns the public URL of the uploaded file
  static Future<String> uploadPDF({
    required String filePath,
    required String fileName,
    required String userId,
  }) async {
    try {
      // Ensure Supabase authentication for file operations
      final authService = SupabaseAuthService();
      final isAuthenticated = authService.canUploadFiles();
      
      if (!isAuthenticated) {
        debugPrint('⚠️ PDFUploadService: Supabase not authenticated, upload may fail');
        throw Exception(authService.getFileUploadErrorMessage());
      } else {
        debugPrint('✅ PDFUploadService: Supabase authentication confirmed');
      }
      
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      
      // Generate unique filename
      const uuid = Uuid();
      final uniqueId = uuid.v4();
      final extension = fileName.split('.').last;
      final uniqueFileName = '${userId}_${uniqueId}.${extension}';
      
      // Upload to Supabase storage
      await SupabaseConfig.client.storage
          .from(bucketName)
          .uploadBinary(
            'pdfs/$uniqueFileName',
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
      
      debugPrint('✅ PDF uploaded successfully: $uniqueFileName');
      
      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from(bucketName)
          .getPublicUrl('pdfs/$uniqueFileName');
      
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Failed to upload PDF: $e');
      throw Exception('Failed to upload PDF: $e');
    }
  }
  
  /// Upload PDF from bytes (for web)
  static Future<String> uploadPDFFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      debugPrint('📄 Starting PDF upload: $fileName (${fileBytes.length} bytes)');
      
      // Ensure Supabase authentication for file operations
      final authService = SupabaseAuthService();
      final isAuthenticated = authService.canUploadFiles();
      
      if (!isAuthenticated) {
        debugPrint('⚠️ PDFUploadService: Supabase not authenticated, upload may fail');
        throw Exception(authService.getFileUploadErrorMessage());
      } else {
        debugPrint('✅ PDFUploadService: Supabase authentication confirmed');
      }
      
      // Generate unique filename
      const uuid = Uuid();
      final uniqueId = uuid.v4();
      final extension = fileName.split('.').last;
      final uniqueFileName = '${userId}_${uniqueId}.${extension}';
      
      debugPrint('📂 Upload path: pdfs/$uniqueFileName');
      
      // Upload to Supabase storage
      await SupabaseConfig.client.storage
          .from(bucketName)
          .uploadBinary(
            'pdfs/$uniqueFileName',
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: false,
            ),
          );
      
      debugPrint('✅ PDF uploaded successfully from bytes: $uniqueFileName');
      
      // Get public URL
      final publicUrl = SupabaseConfig.client.storage
          .from(bucketName)
          .getPublicUrl('pdfs/$uniqueFileName');
      
      debugPrint('🔗 Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Failed to upload PDF from bytes: $e');
      
      // Provide specific error messages for common issues
      if (e.toString().contains('row-level security policy') || e.toString().contains('Unauthorized')) {
        throw Exception('PDF upload failed: Authentication required. Please sign in to upload files.');
      } else if (e.toString().contains('403')) {
        throw Exception('PDF upload failed: Unauthorized access. Please check Supabase bucket permissions.');
      } else if (e.toString().contains('bucket')) {
        throw Exception('PDF upload failed: Storage bucket not found or accessible.');
      }
      
      throw Exception('Failed to upload PDF: $e');
    }
  }
  
  /// Delete a PDF file from Supabase storage
  static Future<bool> deletePDF(String fileName) async {
    try {
      await SupabaseConfig.client.storage
          .from(bucketName)
          .remove(['pdfs/$fileName']);
      
      debugPrint('✅ PDF deleted successfully: $fileName');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete PDF: $e');
      return false;
    }
  }
  
  /// Check if storage bucket exists, create if not
  static Future<void> ensureBucketExists() async {
    try {
      debugPrint('🔍 Checking bucket existence for: $bucketName');
      
      // Try to directly access the bucket instead of listing all buckets
      // This is more reliable as some Supabase configurations don't allow listing buckets
      try {
        await SupabaseConfig.client.storage.from(bucketName).list(path: '', searchOptions: const SearchOptions(limit: 1));
        debugPrint('✅ Storage bucket exists and is accessible: $bucketName');
        return;
      } catch (e) {
        debugPrint('⚠️ Direct bucket access failed: $e');
        
        // Fallback: try to list buckets if direct access fails
        try {
          final buckets = await SupabaseConfig.client.storage.listBuckets();
          debugPrint('📋 Available buckets: ${buckets.map((b) => b.name).toList()}');
          
          // Check if our bucket is in the list
          final bucketExists = buckets.any((bucket) => bucket.name == bucketName);
          
          if (bucketExists) {
            debugPrint('✅ Storage bucket found in bucket list: $bucketName');
            return;
          } else {
            debugPrint('⚠️ Storage bucket not found in bucket list: $bucketName');
          }
        } catch (listError) {
          debugPrint('❌ Failed to list buckets: $listError');
        }
        
        // If we get here, the bucket likely doesn't exist or has permission issues
        throw Exception('Storage bucket "$bucketName" not found or not accessible. Please ensure it exists in your Supabase dashboard with proper RLS policies.');
      }
    } catch (e) {
      debugPrint('❌ Error checking bucket existence: $e');
      debugPrint('📝 Please ensure "$bucketName" bucket exists in your Supabase dashboard with proper permissions');
      throw Exception('Failed to verify storage bucket: $e');
    }
  }
  
  /// Check if bucket exists (returns true/false instead of throwing)
  static Future<bool> checkBucketExists() async {
    try {
      debugPrint('🔍 Quick bucket check for: $bucketName');
      
      // Try direct access first
      await SupabaseConfig.client.storage.from(bucketName).list(path: '', searchOptions: const SearchOptions(limit: 1));
      debugPrint('✅ Bucket exists and is accessible');
      return true;
    } catch (e) {
      debugPrint('❌ Bucket check failed: $e');
      return false;
    }
  }
}
