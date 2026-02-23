import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/save.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemaciaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DemaciaAppBar({
    super.key,
    required this.onSave,
    this.onLongSave,
    this.onLoadSave,          // callback "ישן": אחרי שה-AppBar מחליף currentSave
    this.onSaveSelected,      // callback "חדש": אתה שולט בהחלפת ה-save
    this.onAfterDelete,       // אופציונלי: רענון אחרי מחיקה
  });

  final VoidCallback onSave;
  final VoidCallback? onLongSave;

  /// אם לא מעבירים onSaveSelected, ה-AppBar יחליף currentSave בעצמו ואז יקרא לזה
  final VoidCallback? onLoadSave;

  /// אם מעבירים את זה, ה-AppBar *לא* יחליף currentSave בעצמו.
  /// הוא רק יתן לך את ה-save שנבחר ואתה תעשה switch בצורה חכמה (autosave וכו').
  final Future<void> Function(Save save)? onSaveSelected;

  final Future<void> Function()? onAfterDelete;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AppBar(
      actions: [
        // Current Save Title (אפשר גם להפוך אותו ל"Load" אם תרצה)
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

        // Delete
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

        // Load
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 20),
          child: ElevatedButton(
            onPressed: () => _loadSaves(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              minimumSize: const Size(0, 0),
            ),
            child: Icon(Icons.folder_open, size: isSmallScreen ? 20 : 24),
          ),
        ),

        // Save
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

        // Version
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
        isSmallScreen ? "Demacia" : "Demacia Scouting Maker",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.deepPurple.shade700,
    );
  }

  Future<void> _onDelete(BuildContext context) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            'Choose which save to delete',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 200,
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: MainApp.saves.map((s) {
                  return ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();

                      // Delete from Supabase
                      await DatabaseService().deleteSave(s.index);

                      // Delete local draft
                      await prefs.remove('app_data_${s.index}');

                      // Remove from list
                      MainApp.saves.remove(s);

                      // אם מחקת את הנוכחי - תבחר ראשון פנוי
                      if (MainApp.saves.isNotEmpty) {
                        if (MainApp.currentSave.index == s.index) {
                          MainApp.currentSave = MainApp.saves.first;
                          await prefs.setInt('current_save', MainApp.currentSave.index);
                        }
                      }

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }

                      // רענון חיצוני (Home / Editing)
                      await onAfterDelete?.call();
                    },
                    child: ListTile(
                      title: Text(s.title),
                      leading: Icon(s.icon, color: s.color),
                      trailing: const Icon(Icons.delete),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _loadSaves(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            'Choose which save to load',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            height: 200,
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: MainApp.saves.map((s) {
                  return ElevatedButton(
                    onPressed: () async {
                      // 1) אם אתה רוצה שליטה מלאה (Editing Room) — קוראים ל-onSaveSelected
                      if (onSaveSelected != null) {
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        await onSaveSelected!(s);
                        return;
                      }

                      // 2) ברירת מחדל (כמו שהיה אצלך)
                      MainApp.currentSave = s;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('current_save', s.index);

                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                      onLoadSave?.call();
                    },
                    child: ListTile(
                      title: Text(s.title),
                      leading: Icon(s.icon, color: s.color),
                      trailing: IconButton(
                        onPressed: () => s.editSave(dialogContext),
                        icon: const Icon(Icons.edit),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}