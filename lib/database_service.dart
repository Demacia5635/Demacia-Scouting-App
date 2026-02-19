import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== UPLOAD DATA ====================

  /// Upload data to a table
  Future<Map<String, dynamic>?> uploadData({
    required String table,
    required Map<String, dynamic> data,
    String? onConflict,
  }) async {
    print('upload data: $data');
    try {
      final response = await _supabase
          .from(table)
          .upsert(data, onConflict: onConflict)
          .select()
          .single();
      print('response: $response');
      return response;
    } catch (e) {
      print('Error uploading data: $e');
      rethrow;
    }
  }

  /// Get the latest valid form data from Supabase
  Future<Map<String, dynamic>?> getLatestFormData() async {
    try {
      print('get latest form data');
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
      return _normalizeFormData(formData);
    } catch (e) {
      print('Error fetching latest form: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFormById(int id) async {
    try {
      final response = await _supabase
          .from('data')
          .select('form')
          .eq('id', id)
          .maybeSingle();

      return _normalizeFormData(response?['form']);
    } catch (e) {
      print('Error fetching form by id: $e');
      return null;
    }
  }

  /// Get all non-null form entries
  Future<List<Map<String, dynamic>>> getAllForms() async {
    try {
      print('get all forms');
      final response = await _supabase
          .from('data')
          .select()
          .not('form', 'is', null)
          .order('created_at', ascending: false)
          .limit(6);

      List<Map<String, dynamic>> forms = [];
      for (var item in response) {
        Map<String, dynamic>? form = item['form'];
        if (form != null) {
          forms.add(form);
        }
      }

      return forms;
    } catch (e) {
      print('Error fetching all forms: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllSavesWithForms() async {
    try {
      final saves = await _supabase
          .from('saves')
          .select()
          .order('index', ascending: true);

      final List<Map<String, dynamic>> result = [];

      for (final s in saves) {
        final saveRow = Map<String, dynamic>.from(s);
        final formId = saveRow['form_id'];

        Map<String, dynamic>? form;
        if (formId != null) {
          final row = await _supabase
              .from('data')
              .select('form,created_at')
              .eq('id', formId)
              .maybeSingle();

          form = _normalizeFormData(row?['form']);
          saveRow['created_at'] = row?['created_at'];
        }

        saveRow['form'] = form;
        result.add(saveRow);
      }

      return result;
    } catch (e) {
      print('Error fetching saves with forms: $e');
      return [];
    }
  }

  /// Get the latest form from Supabase
  Future<Map<String, dynamic>?> getForm() async {
    try {
      final response = await _supabase
          .from('data')
          .select()
          .not('form', 'is', null)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('No form found in database');
        return null;
      }

      final form = response['form'];
      print('Latest form retrieved: $form');
      return form;
    } catch (e) {
      print('Error getting latest form: $e');
      return null;
    }
  }

  Map<String, dynamic>? _normalizeFormData(dynamic formData) {
    try {
      if (formData == null) return null;

      dynamic decoded = formData;

      // אם קיבלת JSON כמחרוזת (קורה לפעמים אחרי שינויים/מיגרציות)
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }

      if (decoded is! Map) return null;

      final data = Map<String, dynamic>.from(decoded as Map);

      if (data.containsKey('screens')) return data;
      if (data.containsKey('questions')) return data;
      if (data.containsKey('index') && (data.containsKey('name') || data.containsKey('questions'))) {
        return data;
      }

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
    print('get form by id: $id from table: $table');
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
    print('get form where $column = $value');
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
    print('update form id: $id with data: $formData');
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
      print('get all saves');
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
      print('Uploading save with data: $saveData');
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
      print('Updating save with data: $saveData');
      final existing = await _supabase
          .from('saves')
          .select()
          .eq('index', index)
          .maybeSingle();

      if (existing != null) {
        final response = await _supabase
            .from('saves')
            .update(saveData)
            .eq('index', index)
            .select()
            .single();
        return response;
      } else {
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
