import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/home_page.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemaciaAppBar extends StatelessWidget implements PreferredSizeWidget {
  DemaciaAppBar({
    super.key,
    Future<void> Function()? onLongSave,
    required this.onSave,
    this.onLoadSave,
    this.isInPreview,
  }) : onLongSave = onLongSave ?? _defaultOnLongSave;

  final void Function() onSave;
  final void Function() onLongSave;
  final VoidCallback? onLoadSave; // Add this callback
  bool? isInPreview;

  static Future<void> _defaultOnLongSave() async {}

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AppBar(
      actions: [
        // Current Save Title Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 20),
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 16,
                vertical: 8,
              ),
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              MainApp.currentSave.title,
              style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // Delete Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 20),
          child: ElevatedButton(
            onPressed: () => _onDelete(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              minimumSize: const Size(0, 0),
            ),
            child: Icon(Icons.delete_forever, size: isSmallScreen ? 20 : 24),
          ),
        ),

        // Load Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 20),
          child: ElevatedButton(
            onPressed: () => _loadSaves(context, onLoadSave),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              minimumSize: const Size(0, 0),
            ),
            child: Icon(Icons.folder_open, size: isSmallScreen ? 20 : 24),
          ),
        ),

        // Save Button
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 20),
          child: ElevatedButton(
            onPressed: onSave,
            onLongPress: onLongSave,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              minimumSize: const Size(0, 0),
            ),
            child: Icon(Icons.save, size: isSmallScreen ? 20 : 24),
          ),
        ),

        // Version Text
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 20),
          child: Center(
            child: Text(
              MainApp.version,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 10 : 14,
              ),
            ),
          ),
        ),
      ],
      centerTitle: true,
      elevation: 7,
      title: Text(
        (isInPreview != null) && (isInPreview == true)
            ? "Demacia"
            : "Demacia Scouting Maker",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.deepPurple.shade700,
    );
  }

  static void _onDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Choose which save to delete',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 200,
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: MainApp.saves
                    .map(
                      (p0) => ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();

                          // Delete from Supabase
                          final databaseService = DatabaseService();
                          await databaseService.deleteSave(p0.index);

                          // Delete from SharedPreferences
                          await prefs.remove('app_data_${p0.index}');

                          // Remove from list
                          MainApp.saves.remove(p0);

                          // Set current save to first available
                          if (MainApp.saves.isNotEmpty) {
                            MainApp.currentSave = MainApp.saves[0];
                            await prefs.setInt(
                              'current_save',
                              MainApp.currentSave.index,
                            );
                          }

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }

                          // Refresh the home page
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        child: ListTile(
                          title: Text(p0.title),
                          leading: Icon(p0.icon, color: p0.color),
                          trailing: Icon(Icons.delete),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  static void _loadSaves(BuildContext context, VoidCallback? onLoadSave) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Choose which save to load',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 200,
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: MainApp.saves
                    .map(
                      (p0) => ElevatedButton(
                        onPressed: () async {
                          // Set the current save
                          MainApp.currentSave = p0;

                          // Save to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('current_save', p0.index);

                          // Close the dialog
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }

                          // Trigger reload callback
                          if (onLoadSave != null) {
                            onLoadSave();
                          }
                        },
                        child: ListTile(
                          title: Text(p0.title),
                          leading: Icon(p0.icon, color: p0.color),
                          trailing: IconButton(
                            onPressed: () => p0.editSave(dialogContext),
                            icon: Icon(Icons.edit),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
