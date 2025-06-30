import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/widgets/string_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Save {
  Save({required this.index, String? title, Color? color, IconData? icon})
    : title = title ??= index.toString(),
      color = color ??= Colors.blue,
      icon = icon ??= Icons.save_alt;

  int index;
  String title;
  Color color;
  IconData icon;

  Map<String, dynamic> toJson() => {
    'index': index,
    'title': title,
    'color': {'a': color.a, 'r': color.r, 'g': color.g, 'b': color.b},
    'icon': {'codePoint': icon.codePoint, 'fontFamily': icon.fontFamily},
  };

  factory Save.fromJson(Map<String, dynamic> json) => Save(
    index: json['index'] as int,
    title: json['title'] as String,
    color: Color.from(
      alpha: json['color']['a'] as double,
      red: json['color']['r'] as double,
      green: json['color']['g'] as double,
      blue: json['color']['b'] as double,
    ),
    icon: IconData(
      json['icon']['codePoint'] as int,
      fontFamily: json['icon']['fontFamily'] as String,
    ),
  );

  void editSave(BuildContext context) {
    String pickingName = title;
    Color pickingColor = color;
    IconData pickingIcon = icon;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(15),
          ),
          title: Text('Edit: $title'),
          content: SizedBox(
            height: 200,
            width: 600,
            child: Column(
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      "Rename: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    StringInput(
                      label: "enter new name",
                      initValue: () => title,
                      onChanged: (p0) {
                        pickingName = p0;
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      "Change/Add Icon: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: IconPicker(
                        onChanged: (p0) {
                          pickingIcon = p0;
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        icon = Icons.save_alt;
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ],
                ),

                Row(
                  spacing: 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Change the color",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ColorInput(
                      initValue: () => color,
                      onChanged: (color) {
                        pickingColor = color;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Rename'),
              onPressed: () async {
                title = pickingName;
                icon = pickingIcon;
                color = pickingColor;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void saveSaves() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'saves',
      MainApp.saves.map((p0) => jsonEncode(p0.toJson())).toList(),
    );
    await prefs.setInt('current_save', index);
  }

  Widget build(BuildContext context, void Function() onPressed) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
        saveSaves();
        MainApp.currentSave = this;
        Navigator.pop(context);
      },
      child: ListTile(
        title: Text(title),
        leading: Icon(icon, color: color),
        trailing: IconButton(
          onPressed: () => editSave(context),
          icon: Icon(Icons.edit),
        ),
      ),
    );
  }
}
