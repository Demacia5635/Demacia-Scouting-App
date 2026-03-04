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
    this.onUploaded,
    this.formJson,
  });

  Map<int, Map<int, dynamic>> data;
  Widget Function() previosPage;
  VoidCallback? onUploaded;
  Map<String, dynamic>? formJson;

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

  // Builds {screenIndex: {questionIndex: "label"}} from formJson
  // Also returns the screen name for each screen index
  Map<int, Map<int, String>> _buildLabelMap() {
    final labelMap = <int, Map<int, String>>{};
    if (widget.formJson == null) return labelMap;

    final screens =
        widget.formJson!['screens'] as List? ??
        widget.formJson!['questions'] as List? ??
        [];

    for (int i = 0; i < screens.length; i++) {
      labelMap[i] = {};
      final questions = screens[i] is Map
          ? (screens[i]['questions'] as List? ?? [])
          : [];
      for (final q in questions) {
        if (q is Map) {
          final index = q['index'] as int?;
          final label =
              (q['sheetsTitle'] as String? ??
                      q['question']?['sheetsTitle'] as String? ??
                      q['question']?['label'] as String? ??
                      'field_${i}_$index')
                  .toString()
                  .trim();
          if (index != null) {
            labelMap[i]![index] = label;
          }
        }
      }
    }
    return labelMap;
  }

  // Returns screen name (e.g. "Auto", "Teleop") for a given screen index
  String _getScreenName(int screenIndex) {
    if (widget.formJson == null) return 'screen$screenIndex';
    final screens = widget.formJson!['screens'] as List? ?? [];
    if (screenIndex < screens.length && screens[screenIndex] is Map) {
      return (screens[screenIndex]['name'] as String? ?? 'screen$screenIndex')
          .toString()
          .trim();
    }
    return 'screen$screenIndex';
  }

  Future<void> sendToSheet() async {
    final labelMap = _buildLabelMap();

    // ✅ First pass: collect all labels across all screens to detect duplicates
    final allLabels = <String>[];
    for (var screenEntry in widget.data.entries) {
      final screenIndex = screenEntry.key;
      for (var qEntry in screenEntry.value.entries) {
        final qIndex = qEntry.key;
        final label =
            labelMap[screenIndex]?[qIndex] ?? 'screen${screenIndex}_q$qIndex';
        allLabels.add(label);
      }
    }

    // Find labels that appear more than once (duplicates across screens)
    final labelCounts = <String, int>{};
    for (final l in allLabels) {
      labelCounts[l] = (labelCounts[l] ?? 0) + 1;
    }
    final duplicateLabels = labelCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toSet();

    // ✅ Second pass: build dataMap, prefixing duplicates with screen name
    final Map<String, dynamic> dataMap = {};
    for (var screenEntry in widget.data.entries) {
      final screenIndex = screenEntry.key;
      final screenName = _getScreenName(screenIndex);
      for (var qEntry in screenEntry.value.entries) {
        final qIndex = qEntry.key;
        final value = valueToString(qEntry.value);
        if (value == '\u200B') continue;

        final rawLabel =
            labelMap[screenIndex]?[qIndex] ?? 'screen${screenIndex}_q$qIndex';

        // ✅ If this label appears in multiple screens, prefix with screen name
        final finalLabel = duplicateLabels.contains(rawLabel)
            ? '${screenName}_$rawLabel'
            : rawLabel;

        dataMap[finalLabel] = value;
      }
    }

    print('Sending to sheet: $dataMap');

    final url = Uri.parse(
      'https://script.google.com/macros/s/AKfycbzwDCPVAost-Crrql2l6CiGi8C5KUmH0ZFE6UBmFASLsN-l9mlzeOMrpbwlyD7LVM4svg/exec',
    );

    final client = http.Client();
    try {
      final encodedBody = jsonEncode(dataMap);

      // Step 1: POST — don't auto-follow redirect
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..followRedirects = false
        ..body = encodedBody;

      final firstResponse = await client.send(request);

      http.Response response;

      if (firstResponse.statusCode == 302) {
        // Google redirects require GET
        final redirectUrl = Uri.parse(firstResponse.headers['location']!);
        response = await http.get(redirectUrl);
      } else {
        response = await http.Response.fromStream(firstResponse);
      }

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseJson = jsonDecode(response.body);
      if (responseJson['status'] == 'error') {
        throw Exception(responseJson['message']);
      }
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
                                  widget.onUploaded?.call();
                                  Navigator.of(
                                    context,
                                  ).popUntil((route) => route.isFirst);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 4),
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
