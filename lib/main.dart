import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scouting_qr_maker/firebase_options.dart';
import 'package:scouting_qr_maker/save.dart';
import 'package:scouting_qr_maker/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final prefs = await SharedPreferences.getInstance();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (prefs.containsKey('saves')) {
    MainApp.saves = [];
    for (var save in prefs.getStringList('saves')!) {
      MainApp.saves.add(Save.fromJson(jsonDecode(save)));
    }
  }

  if (prefs.containsKey('current_save')) {
    MainApp.currentSave = MainApp.saves[prefs.getInt('current_save')!];
  }

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
