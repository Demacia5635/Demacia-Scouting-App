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

  /// Get the latest valid form data from Supabase
  /// Handles multiple data formats and returns parsed FormPage data
  Future<Map<String, dynamic>?> getLatestFormData() async {
    try {
      final response = await _supabase
          .from('data')
          .select()
          .not('form', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response['form'] == null) {
        print('No form data found in database');
        return null;
      }

      final formData = response['form'];

      // Handle different data formats
      return _normalizeFormData(formData);
    } catch (e) {
      print('Error fetching latest form: $e');
      return null;
    }
  }

  /// Get all non-null form entries
  Future<List<Map<String, dynamic>>> getAllForms() async {
    try {
      final response = await _supabase
          .from('data')
          .select()
          .not('form', 'is', null)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> forms = [];

      for (var row in response) {
        if (row['form'] != null) {
          final normalized = _normalizeFormData(row['form']);
          if (normalized != null) {
            forms.add(normalized);
          }
        }
      }

      return forms;
    } catch (e) {
      print('Error fetching all forms: $e');
      return [];
    }
  }

  /// Normalize different data formats into a consistent structure
  Map<String, dynamic>? _normalizeFormData(dynamic formData) {
    try {
      if (formData == null) return null;

      Map<String, dynamic> data;

      // If it's already a Map, use it directly
      if (formData is Map<String, dynamic>) {
        data = formData;
      } else if (formData is String) {
        // If it's a string, it might be JSON encoded
        return null;
      } else {
        return null;
      }

      // Check if data has "screens" wrapper
      if (data.containsKey('screens')) {
        // Handle {"screens":[{"questions":[],"index":9,"name":"..."}]}
        final screens = data['screens'];
        if (screens is List && screens.isNotEmpty) {
          // Return the first screen as the form data
          if (screens[0] is Map<String, dynamic>) {
            return screens[0] as Map<String, dynamic>;
          }
        }
      }

      // Check if data has "questions" at root level
      if (data.containsKey('questions')) {
        // Handle {"questions":[{"index":1,"question":{"label":"..."},...}]}
        return data;
      }

      // If it has index, name, and other FormPage fields, it's already normalized
      if (data.containsKey('index') &&
          (data.containsKey('name') || data.containsKey('questions'))) {
        return data;
      }

      print('Unrecognized data format: ${data.keys}');
      return null;
    } catch (e) {
      print('Error normalizing form data: $e');
      return null;
    }
  }

  /// Get form by ID with format normalization
  Future<Map<String, dynamic>?> getById(
    String table,
    dynamic id, {
    String idColumn = 'id',
  }) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (response != null && response['form'] != null) {
        return _normalizeFormData(response['form']);
      }
      return null;
    } catch (e) {
      print('Error fetching by ID: $e');
      return null;
    }
  }

  /// Get form by specific criteria
  Future<Map<String, dynamic>?> getFormWhere({
    required String column,
    required dynamic value,
  }) async {
    try {
      final response = await _supabase
          .from('data')
          .select()
          .eq(column, value)
          .not('form', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['form'] != null) {
        return _normalizeFormData(response['form']);
      }
      return null;
    } catch (e) {
      print('Error fetching form where $column = $value: $e');
      return null;
    }
  }

  /// Delete a form entry
  Future<bool> deleteForm(int id) async {
    try {
      await _supabase.from('data').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting form: $e');
      return false;
    }
  }

  /// Update existing form data
  Future<Map<String, dynamic>?> updateForm({
    required int id,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final response = await _supabase
          .from('data')
          .update({'form': formData})
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error updating form: $e');
      return null;
    }
  }

  // ==================== SAVES MANAGEMENT ====================

  /// Get all saves from Supabase
  Future<List<Map<String, dynamic>>> getAllSaves() async {
    try {
      final response = await _supabase
          .from('saves')
          .select()
          .order('index', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching saves: $e');
      return [];
    }
  }

  /// Upload/Insert a new save
  Future<Map<String, dynamic>?> uploadSave(
    Map<String, dynamic> saveData,
  ) async {
    try {
      final response = await _supabase
          .from('saves')
          .insert(saveData)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error uploading save: $e');
      return null;
    }
  }

  /// Update an existing save
  Future<Map<String, dynamic>?> updateSave({
    required int index,
    required Map<String, dynamic> saveData,
  }) async {
    try {
      // First check if the save exists
      final existing = await _supabase
          .from('saves')
          .select()
          .eq('index', index)
          .maybeSingle();

      if (existing != null) {
        // Update existing save
        final response = await _supabase
            .from('saves')
            .update(saveData)
            .eq('index', index)
            .select()
            .single();
        return response;
      } else {
        // Insert new save if it doesn't exist
        final response = await _supabase
            .from('saves')
            .insert(saveData)
            .select()
            .single();
        return response;
      }
    } catch (e) {
      print('Error updating save: $e');
      return null;
    }
  }

  /// Delete a save
  Future<bool> deleteSave(int index) async {
    try {
      await _supabase.from('saves').delete().eq('index', index);
      return true;
    } catch (e) {
      print('Error deleting save: $e');
      return false;
    }
  }
}
