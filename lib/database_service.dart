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

  // ==================== READ DATA ====================

  /// Read data from a table with realtime updates
  Stream<List<Map<String, dynamic>>> readData(
    String table, {
    String primaryKey = 'id',
    String? orderBy,
    bool ascending = true,
  }) {
    SupabaseStreamBuilder query = _supabase
        .from(table)
        .stream(primaryKey: [primaryKey]);

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    return query;
  }
}
