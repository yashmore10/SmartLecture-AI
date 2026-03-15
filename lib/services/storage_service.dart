import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadLecture(String filePath) async {
    try {
      final file = File(filePath);
      final fileName =
          "lecture_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _supabase.storage
          .from('lectures')
          .upload(fileName, file);

      final publicUrl = _supabase.storage
          .from('lectures')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }
}
