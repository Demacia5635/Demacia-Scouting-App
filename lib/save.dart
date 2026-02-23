import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/widgets/string_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scouting_qr_maker/database_service.dart';

class Save {
  Save({
    required this.index,
    String? title,
    Color? color,
    IconData? icon,
    this.formId,
  }) : title = title ?? index.toString(),
       color = color ?? Colors.blue,
       icon = icon ?? Icons.save_alt;

  int index;
  String title;
  Color color;
  IconData icon;
  int? formId;

  Map<String, dynamic> toJson() => {
    'index': index,
    'title': title,
    'color': {'a': color.a, 'r': color.r, 'g': color.g, 'b': color.b},
    'icon': {'codePoint': icon.codePoint, 'fontFamily': icon.fontFamily},
    'form_id': formId,
  };

  factory Save.fromJson(Map<String, dynamic> json) {
    Color parsedColor;
    if (json['color'] is Map) {
      final colorMap = json['color'] as Map<String, dynamic>;
      parsedColor = Color.from(
        alpha: (colorMap['a'] as num?)?.toDouble() ?? 1.0,
        red: (colorMap['r'] as num?)?.toDouble() ?? 0.0,
        green: (colorMap['g'] as num?)?.toDouble() ?? 0.0,
        blue: (colorMap['b'] as num?)?.toDouble() ?? 1.0,
      );
    } else {
      parsedColor = Colors.blue;
    }

    IconData parsedIcon;
    if (json['icon'] is Map) {
      final iconMap = json['icon'] as Map<String, dynamic>;
      parsedIcon = IconData(
        iconMap['codePoint'] as int? ?? Icons.save_alt.codePoint,
        fontFamily: iconMap['fontFamily'] as String?,
      );
    } else {
      parsedIcon = Icons.save_alt;
    }

    return Save(
      index: json['index'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      color: parsedColor,
      icon: parsedIcon,
      formId: json['form_id'] as int?, // Add this
    );
  }

  // Rest of the class remains the same...
  void editSave(BuildContext context) {
    String pickingName = title;
    Color pickingColor = color;
    IconData pickingIcon = icon;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
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
                        pickingIcon = Icons.save_alt;
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
                      onChanged: (newColor) {
                        pickingColor = newColor;
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
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                title = pickingName;
                icon = pickingIcon;
                color = pickingColor;

                await saveSaves();

                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveSaves() async {
    print('saves save');
    try {
      final databaseService = DatabaseService();

      print('JSON: \n${toJson()}');
      //await databaseService.updateSave(index: index, saveData: toJson());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_save', index);

      print('Save updated successfully in Supabase');
    } catch (e) {
      print('Error saving to Supabase: $e');
    }
  }

  Widget build(BuildContext context, void Function() onPressed) {
    return ElevatedButton(
      onPressed: () async {
        onPressed();
        await saveSaves();
        MainApp.currentSave = this;

        if (context.mounted) {
          Navigator.pop(context);
        }
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
