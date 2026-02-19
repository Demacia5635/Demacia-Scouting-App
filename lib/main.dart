import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/save.dart';
import 'package:scouting_qr_maker/home_page.dart';
import 'package:scouting_qr_maker/form_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: 'https://jnqbzzttvrjeudzbonix.supabase.co',
    anonKey: 'sb_publishable_W3CWjvB06rZEkSHJqccKEw_x5toioxg',
  );

  //DatabaseService databaseService = DatabaseService();//TODO
  final db = DatabaseService(); 

  // Load the three latest saves with their forms
  try {
    final savesWithForms = await db.getAllSavesWithForms();

    if (savesWithForms.isNotEmpty) {
      MainApp.saves = savesWithForms.map((m) => Save.fromJson(m)).toList();
    }
    
    final savedCurrent = prefs.getInt('current_save');

    if (MainApp.saves.isNotEmpty) {
      MainApp.currentSave = (savedCurrent == null)
          ? MainApp.saves.first
          : (MainApp.saves.firstWhere(
              (s) => s.index == savedCurrent,
              orElse: () => MainApp.saves.first,
            ));
      await prefs.setInt('current_save', MainApp.currentSave.index);
    }
  } catch (e) {
    print('Error loading saves: $e');
    // Keep default saves on error
  }

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  MainApp.version = packageInfo.version;

  runApp(MainApp());
}

void save(Map<String, dynamic> json, Save file) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_data_${file.index}', jsonEncode(json));

  // Upload to Supabase and get the form ID
  final databaseService = DatabaseService();
  final result = await databaseService.uploadData(
    table: 'data',
    data: {'form': json},
  );

  // Link the form to this save
  if (result != null && result['id'] != null) {
    file.formId = result['id'] as int;
    await file.saveSaves(); // Save the updated save with form_id
  }

  MainApp.currentSave = file;
}

void longSave(
  Map<String, dynamic> json,
  BuildContext context,
  void Function() reload,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(
          'Choose where to save',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          height: 200,
          width: 500,
          child: Column(
            spacing: 10,
            children: MainApp.saves
                .map(
                  (p0) => p0.build(context, () {
                    reload();
                    save(json, p0);
                  }),
                )
                .toList(),
          ),
        ),
      );
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static String version = '';

  static List<Save> saves = [
    Save(index: 0, title: 'Save #1', color: Colors.red, icon: Icons.filter_1),
    Save(index: 1, title: 'Save #2', color: Colors.green, icon: Icons.filter_2),
    Save(index: 2, title: 'Save #3', color: Colors.blue, icon: Icons.filter_3),
  ];
  static Save currentSave = saves[0];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Demacia Scouting Maker",
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

/// Helper function to load form from Supabase and convert it to FormPage - No ones using this
Future<FormPage?> loadFormPageFromSupabase() async {
  try {
    final databaseService = DatabaseService();
    final formData = await databaseService.getLatestFormData();

    if (formData == null) {
      print('No form data found in Supabase');
      return null;
    }

    // Convert the form data to FormPage
    final formPage = FormPage.fromJson(
      formData,
      isChangable: false, // Set to true if you want to edit
      init: () => null,
    );

    return formPage;
  } catch (e) {
    print('Error loading FormPage from Supabase: $e');
    return null;
  }
}
