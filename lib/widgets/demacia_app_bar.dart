import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/home_page.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

class DemaciaAppBar extends AppBar {
  DemaciaAppBar({
    super.key,
    Future<void> Function()? onLongSave,
    required this.onSave,
  }) : onLongSave = onLongSave ?? (() {}),
       super(
         actions: [
           Container(
             margin: EdgeInsets.symmetric(horizontal: 20),
             child: Builder(
               builder: (context) {
                 return ElevatedButton(
                   onPressed: null,
                   child: Text(MainApp.currentSave.title),
                 );
               },
             ),
           ),

           Container(
             margin: EdgeInsets.symmetric(horizontal: 20),
             child: Builder(
               builder: (context) {
                 return ElevatedButton(
                   onPressed: () => onDelete(context),
                   child: Icon(Icons.delete_forever),
                 );
               },
             ),
           ),

           Container(
             margin: EdgeInsets.symmetric(horizontal: 20),
             child: Builder(
               builder: (context) {
                 return ElevatedButton(
                   onPressed: () => loadSaves(context),
                   child: Icon(Icons.folder_open),
                 );
               },
             ),
           ),

           Container(
             margin: EdgeInsets.symmetric(horizontal: 20),
             child: ElevatedButton(
               onPressed: onSave,

               onLongPress: onLongSave,
               child: Icon(Icons.save),
             ),
           ),

           Container(
             margin: EdgeInsets.symmetric(horizontal: 20),
             child: Text(
               MainApp.version,
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.white),
             ),
           ),
         ],
         centerTitle: true,
         elevation: 7,
         title: Text(
           "Demacia Scouting Maker",
           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
         ),
         backgroundColor: Colors.deepPurple.shade700,
       );

  void Function() onSave;
  void Function() onLongSave;

  static void onDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Choose which save to delete',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 200,
            width: 500,
            child: Column(
              spacing: 10,
              children: MainApp.saves
                  .map(
                    (p0) => p0.build(context, () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('current_save');
                      await prefs.remove('app_data_${p0.index}');
                      MainApp.currentSave = MainApp.saves[0];
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (p0) => HomePage()),
                        (Route<dynamic> route) => false,
                      );
                    }),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  static void loadSaves(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Choose which save to load',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 200,
            width: 500,
            child: Column(
              spacing: 10,
              children: MainApp.saves
                  .map(
                    (p0) => p0.build(context, () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('current_save', p0.index);
                      MainApp.currentSave = p0;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (p0) => HomePage()),
                        (Route<dynamic> route) => false,
                      );
                    }),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
