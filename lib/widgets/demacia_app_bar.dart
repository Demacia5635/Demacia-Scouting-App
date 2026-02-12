import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/home_page.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemaciaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DemaciaAppBar({
    super.key,
    Future<void> Function()? onLongSave,
    required this.onSave,
  }) : onLongSave = onLongSave ?? _defaultOnLongSave;

  final void Function() onSave;
  final void Function() onLongSave;

  static Future<void> _defaultOnLongSave() async {}

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Now we can safely access MediaQuery here
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
            onPressed: () => _loadSaves(context),
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
        isSmallScreen ? "Demacia" : "Demacia Scouting Maker",
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
      builder: (context) {
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
                      (p0) => p0.build(context, () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('current_save');
                        await prefs.remove('app_data_${p0.index}');
                        MainApp.currentSave = MainApp.saves[0];
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (p0) => HomePage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      }),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  static void _loadSaves(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
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
                      (p0) => p0.build(context, () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('current_save', p0.index);
                        MainApp.currentSave = p0;
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (p0) => HomePage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      }),
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
