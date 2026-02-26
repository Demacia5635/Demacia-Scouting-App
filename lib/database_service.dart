import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== UPLOAD DATA ====================

  /// Upload data to a table
  Future<Map<String, dynamic>?> uploadData({
    required String table,
    required Map<String, dynamic> data,
    String? onConflict,
  }) async {
    //print('upload data: $data');
    print('\n IN UPLOAD FUNC');
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

  Stream<List<Map<String, dynamic>>> getThreeLatestSavesStream() {
    return _supabase
        .from('data')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(3)
        .asyncMap((List<Map<String, dynamic>> response) async {
          // Changed to asyncMap to allow SharedPreferences access
          List<Map<String, dynamic>> savesWithForms = [];
          final prefs = await SharedPreferences.getInstance();

          for (int i = 0; i < response.length; i++) {
            final row = response[i];
            var formData = row['form'];

            // Logic from your Future: if form is null or empty, check SharedPreferences
            // if (formData == null || (formData is Map && formData.isEmpty)) {
            //   // final localData = prefs.getString('app_data_$i');
            //   // if (localData != null && localData.isNotEmpty) {
            //   //   try {
            //   //     formData = jsonDecode(localData);
            //   //   } catch (e) {
            //   //     formData = null;
            //   //   }
            //   // }
            //   await prefs.remove('app_data_$i');
            //   formData = null;
            // }

            // if (formData is Map<String, dynamic> &&
            //     formData['screens'] != null) {
            //   formData = Map<String, dynamic>.from(formData);
            //   var screens = List.from(formData['screens']);
            //   for (int s = 0; s < screens.length; s++) {
            //     if (screens[s] is Map) {
            //       screens[s] = Map<String, dynamic>.from(screens[s]);
            //       screens[s]['index'] = s;
            //     }
            //   }
            //   formData['screens'] = screens;
            // }

            savesWithForms.add({
              'index': i,
              'id': row['id'],
              'title': 'Save #${i + 1}',
              'color': _getColorForIndex(i),
              'icon': _getIconForIndex(i),
              'form': formData ?? {'screens': []},
              'created_at':
                  row['created_at'] ?? DateTime.now().toIso8601String(),
            });
          }
          return savesWithForms;
        });
  }

  Map<String, double> _getColorForIndex(int i) {
    switch (i) {
      case 0:
        return {'a': 1.0, 'r': 1.0, 'g': 0.0, 'b': 0.0};
      case 1:
        return {'a': 1.0, 'r': 0.0, 'g': 1.0, 'b': 0.0};
      case 2:
        return {'a': 1.0, 'r': 0.0, 'g': 0.0, 'b': 1.0};
      default:
        return {'a': 1.0, 'r': 0.5, 'g': 0.5, 'b': 0.5};
    }
  }

  Map<String, dynamic> _getIconForIndex(int i) {
    IconData iconData;
    switch (i) {
      case 0:
        iconData = Icons.filter_1;
        break;
      case 1:
        iconData = Icons.filter_2;
        break;
      case 2:
        iconData = Icons.filter_3;
        break;
      default:
        iconData = Icons.help_outline;
    }

    return {'codePoint': iconData.codePoint, 'fontFamily': 'MaterialIcons'};
  }

  Future<int> getLatestFormId() async {
    final id = await _supabase.from('data').select('id').limit(1);
    if (id.isEmpty) {
      return 1;
    }
    //return id;
    print('ID!!!: $id, id!: ${id[0]['id']}');
    return id[0]['id'];
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
      print('get form by database id: $id');
      final response = await _supabase
          .from('data')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null && response['form'] != null) {
        return response['form'];
      }
      return null;
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

  Future<void> testData() async {
    final res = await _supabase
        .from('data')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen((List<Map<String, dynamic>> data) {
          print('Stream Data: $data');
        });

    print('Stream Data: $res');
  }

  /// Get the three most recent s with their associated form data
  Future<List<Map<String, dynamic>>> getThreeLatestSavesWithForms() async {
    try {
      print('Getting three latest saves with forms');

      // Get the 3 most recent data entries
      final response = await _supabase
          .from('data')
          .select()
          .order('created_at', ascending: false)
          .limit(3);

      List<Map<String, dynamic>> savesWithForms = [];
      print('resp in last three: ${response[0].toString()}');
      for (int i = 0; i < response.length; i++) {
        if (response[i]['form'] is Map<String, dynamic> &&
            response[i]['form'].isEmpty) {
          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          savesWithForms.add({
            'index': i,
            'title': 'Save #${i + 1}',
            'color': i == 0
                ? {'a': 1.0, 'r': 1.0, 'g': 0.0, 'b': 0.0} // Red
                : i == 1
                ? {'a': 1.0, 'r': 0.0, 'g': 1.0, 'b': 0.0} // Green
                : {'a': 1.0, 'r': 0.0, 'g': 0.0, 'b': 1.0}, // Blue
            'icon': {
              'codePoint': i == 0
                  ? Icons.filter_1.codePoint
                  : i == 1
                  ? Icons.filter_2.codePoint
                  : Icons.filter_3.codePoint,
              'fontFamily': 'MaterialIcons',
            },
            'form': sharedPreferences.getString('app_data_$i') != null
                ? (sharedPreferences.getString('app_data_$i')!)
                : "",
            'created_at': DateTime.now(),
          });
        } else {
          savesWithForms.add({
            'index': i,
            'title': 'Save #${i + 1}',
            'color': i == 0
                ? {'a': 1.0, 'r': 1.0, 'g': 0.0, 'b': 0.0} // Red
                : i == 1
                ? {'a': 1.0, 'r': 0.0, 'g': 1.0, 'b': 0.0} // Green
                : {'a': 1.0, 'r': 0.0, 'g': 0.0, 'b': 1.0}, // Blue
            'icon': {
              'codePoint': i == 0
                  ? Icons.filter_1.codePoint
                  : i == 1
                  ? Icons.filter_2.codePoint
                  : Icons.filter_3.codePoint,
              'fontFamily': 'MaterialIcons',
            },
            'form': response[i]['form'],
            'created_at': response[i]['created_at'],
            'id': response[i]['id'],
          });
        }
        print('form i: $i, ${response[i]['form']}');
        print('is empty ${response[i]['form'] == {}}');
      }

      print('Fetched ${savesWithForms.length} saves with forms');

      print('resp len: ${response.length}');
      for (int i = 0; i < response.length; i++) {
        final row = response[i];
        print('b4');
        print('row: ${row['form']} is null? : ${row['form'] == null}');
        final screens = row['form'] == null
            ? []
            : row['form']['screens'] as List;
        print('screens: ${screens.length} created at: ${row['created_at']}');
      }
      print('end');
      print('final data: $savesWithForms');
      return savesWithForms;
    } catch (e) {
      print('Error fetching latest saves with forms: $e');
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

  /// Normalize different data formats into a consistent structure
  Map<String, dynamic>? _normalizeFormData(dynamic formData) {
    try {
      print('normalize form data');
      if (formData == null) return null;

      Map<String, dynamic> data;

      if (formData is Map<String, dynamic>) {
        data = formData;
      } else if (formData is String) {
        return null;
      } else {
        return null;
      }

      // Check if data has "screens" wrapper
      if (data.containsKey('screens')) {
        return data; // Return the whole structure with screens
      }

      // Check if data has "questions" at root level
      if (data.containsKey('questions')) {
        return data;
      }

      // If it has index, name, and other FormPage fields
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

  Future<bool> dbHasData() async {
    final data = await _supabase.from('data').select('form').limit(1);
    print('data: $data');
    return data.isNotEmpty;
  }

  /// Update an existing save
  @Deprecated('Useless')
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
