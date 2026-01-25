import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== UPLOAD DATA ====================

  /// Upload data to a table
  Future<Map<String, dynamic>?> uploadData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _supabase
          .from(table)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error uploading data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getLatestForm() async {
    try {
      final response = await _supabase
          .from('data')
          .select()
          .not('form', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['form'] != null) {
        return response['form'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching latest form: $e');
      return null;
    }
  }
}
