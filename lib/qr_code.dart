import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:scouting_qr_maker/widgets/editing_enum.dart';
import 'package:scouting_qr_maker/widgets/section_divider.dart';

class QrCode extends StatefulWidget {
  QrCode({super.key, required this.data, required this.previosPage});

  // Map<int, List<String>> data;
  Map<int, Map<int, dynamic>> data;
  Widget Function() previosPage;

  @override
  State<StatefulWidget> createState() => QrCodeState();
}

class QrCodeState extends State<QrCode> {
  String qrData = '';

  late FocusNode focusNode;

  String valueToString(dynamic value) {
    switch (value.runtimeType) {
      case bool:
      case double:
      case int:
      case String:
        return value.toString();
      case IconData:
        return '${(value as IconData).codePoint},${(value).fontFamily}';
      case Color:
        return (value as Color).toHexString(includeHashSign: true);
      default:
        if (value is Set<Entry>) {
          String x = '';
          for (int i = 0; i < value.length; i++) {
            if (i != 0) {
              x += '|';
            }
            x += value.elementAt(i).sheetsTitle;
          }
          return x;
        }
        return '\u200B'; // Placeholder for unsupported types or null
    }
  }

  @override
  void initState() {
    super.initState();

    for (Map<int, dynamic> screen in widget.data.values) {
      for (dynamic value in screen.values) {
        if (valueToString(value) != '\u200B') {
          qrData += '${valueToString(value)}, ';
        }
      }
      qrData += ',';
    }

    focusNode = FocusNode();
  }

  /// Handles raw keyboard events.
  void handleKeyEvent(RawKeyEvent event) {
    // Check if the event is a key down event and the pressed key is the Escape key.
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if there's a route to pop (i.e., not the very first screen)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Pop the current route
      }
    }

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // Check if there's a route to pop (i.e., not the very first screen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.previosPage()),
        );
    }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: focusNode,
    onKey: handleKeyEvent,
    autofocus: true,
    child: Scaffold(
      appBar: DemaciaAppBar(
        // onSave: () => save(widget.data, MainApp.currentSave),
        // onLongSave: () => longSave(widget.data, context, () => setState(() {})),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              spacing: 30,
              children: [
                SectionDivider(
                  label: 'Qr Code',
                  lineColor: Colors.cyanAccent.shade700,
                ),
                QrImageView(
                  data: qrData,
                  size: 300,
                  backgroundColor: Colors.white,
                ),
    
                Text(
                  qrData,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),             
                ),
    
                Row(
                  spacing: 100,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => widget.previosPage(),
                          ),
                        );
                      },
                      child: Icon(Icons.navigate_before),
                    ),
                    ElevatedButton(
                      onPressed: null,
                      child: Icon(Icons.navigate_next),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
