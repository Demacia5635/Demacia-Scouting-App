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

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jnqbzzttvrjeudzbonix.supabase.co',
    anonKey: 'sb_publishable_W3CWjvB06rZEkSHJqccKEw_x5toioxg',
  );

  DatabaseService databaseService = DatabaseService();

  // Load saves from Supabase
  try {
    final savesData = await databaseService.getAllSaves();

    if (savesData.isNotEmpty) {
      print('Successfully loaded ${savesData.length} saves from Supabase');

      // Convert JSON data to Save objects
      MainApp.saves = savesData.map((saveJson) {
        return Save.fromJson(saveJson);
      }).toList();

      print('Loaded saves: ${MainApp.saves.map((s) => s.title).join(", ")}');
    } else {
      print('No saves found in Supabase, using default saves');
      // Keep the default saves if nothing in database
    }
  } catch (e) {
    print('Error loading saves from Supabase: $e');
    print('Using default saves');
    // Keep the default saves on error
  }

  // Load current save preference from SharedPreferences
  if (prefs.containsKey('current_save')) {
    int saveIndex = prefs.getInt('current_save')!;
    if (saveIndex < MainApp.saves.length) {
      MainApp.currentSave = MainApp.saves[saveIndex];
    }
  }

  // Get package info
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  MainApp.version = packageInfo.version;

  runApp(MainApp());
}

void save(Map<String, dynamic> json, Save file) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_data_${file.index}', jsonEncode(json));
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

/// Helper function to load form from Supabase and convert it to FormPage
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
