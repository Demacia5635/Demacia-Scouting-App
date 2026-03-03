import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:scouting_qr_maker/widgets/editing_enum.dart';
import 'package:scouting_qr_maker/widgets/section_divider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:http/http.dart' as http;

void main() {}

class QrCode extends StatefulWidget {
  QrCode({
    super.key,
    required this.data,
    required this.previosPage,
    this.onUploaded, // ✅ new callback — called only on successful upload
  });

  Map<int, Map<int, dynamic>> data;
  Widget Function() previosPage;
  VoidCallback? onUploaded;

  @override
  State<StatefulWidget> createState() => QrCodeState();
}

class QrCodeState extends State<QrCode> {
  String qrData = '';
  bool _isUploading = false;

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
        break;
      case Color:
        return (value as Color).toHexString(includeHashSign: true);
        break;
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
        return '\u200B';
    }
  }

  Future<void> sendToSheet() async {
    Map<String, dynamic> dataMap = {};
    for (var entry in widget.data.entries) {
      for (var screenEntry in entry.value.entries) {
        String value = valueToString(screenEntry.value);
        if (value != '\u200B') {
          dataMap[screenEntry.key.toString()] = value;
        }
      }
    }

    final url = Uri.parse(
      'https://script.google.com/macros/s/AKfycbyZydAiTiAP5LdN3fPUjN5-xihFFbeN4-T9mrUpBe8JZHcwxYOKXbxEliwRmWfEBwy35g/exec',
    );

    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(dataMap);

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
    } finally {
      client.close();
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    _loadData();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    for (Map<int, dynamic> screen in widget.data.values) {
      for (dynamic value in screen.values) {
        if (valueToString(value) != '\u200B') {
          qrData += '${valueToString(value)}, ';
        }
      }
      qrData += ',';
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _uploadData() async {
    Map<String, Map<String, String>> dataMap = {};
    for (var entry in widget.data.entries) {
      Map<String, String> screenMap = {};
      for (var screenEntry in entry.value.entries) {
        String value = valueToString(screenEntry.value);
        if (value != '\u200B') {
          screenMap[screenEntry.key.toString()] = value;
        }
      }
      dataMap[entry.key.toString()] = screenMap;
    }

    await DatabaseService().uploadData(
      table: 'answer',
      data: {'answer': dataMap},
    );
  }

  void handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
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
      appBar: DemaciaAppBar(onSave: () {}, isInPreview: true),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                Row(
                  spacing: 50,
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
                      onPressed: _isUploading
                          ? null
                          : () async {
                              setState(() => _isUploading = true);
                              try {
                                await _uploadData();
                                await sendToSheet();
                                if (context.mounted) {
                                  // ✅ Only resets form data when upload button is pressed
                                  widget.onUploaded?.call();
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Upload failed: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isUploading = false);
                                }
                              }
                            },
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.upload),
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