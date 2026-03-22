import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

void main() {
  runApp(MaterialApp(home: Scanner(), debugShowCheckedModeBanner: false));
}

class Scanner extends StatefulWidget {
  @override
  QRCodeState createState() => QRCodeState();
}

class QRCodeState extends State<Scanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? resolt;
  QRViewController? controller;
  bool isScanMode = false;
  bool isSending = false;

  @override
  void reassemble() {
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        resolt = scanData;
      });

      if (scanData.code != null) {
        final parsed = parseQRCode(scanData.code!);
        sendToSheet(parsed);
        Navigator.of(context).pop();
      }
    });
  }

  Map<String, dynamic> parseQRCode(String code) {
    final parts = code.split(',').map((s) => s.trim()).toList();

    // parts[1] = team number, parts[2] = match number
    final matchTeam = parts.length > 1 ? parts[1] : '';
    final matchNum = parts.length > 2 ? parts[2] : '';

    // ID = match number + team number
    final id = '${matchNum}_${matchTeam}';

    return {
      'השם שלכם': parts.length > 0 ? parts[0] : '',
      'מספר קבוצה': parts.length > 1 ? parts[1] : '',
      'מספר משחק': parts.length > 2 ? parts[2] : '',
      'איפה התחיל': parts.length > 3 ? parts[3] : '',
      'איפה עבר': parts.length > 4 ? parts[4] : '',
      '?ירה': parts.length > 5 ? parts[5] : '',
      'אם כן כמה נקודות עשה בערך': parts.length > 6 ? parts[6] : '',
      'טיפס': parts.length > 7 ? parts[7] : '',
      'עובר סנטרליין': parts.length > 8 ? parts[8] : '',
      'איפה משיג כדורים?': parts.length > 9 ? parts[9] : '',
      'Auto_דליוורי': parts.length > 10 ? parts[10] : '',
      'ירי': parts.length > 11 ? parts[11] : '',
      'כמה נקודות עשה בירי': parts.length > 12 ? parts[12] : '',
      'טיפוס': parts.length > 13 ? parts[13] : '',
      'טל-אופ_דליוורי': parts.length > 14 ? parts[14] : '',
      'הגנה': parts.length > 15 ? parts[15] : '',
      'מה עובר': parts.length > 16 ? parts[16] : '',
      'id': id,
    };
  }

  Future<void> flipeCmera() async {
    await controller?.flipCamera();
  }

  Future<void> sendToSheet(Map<String, dynamic> data) async {
    setState(() => isSending = true);

    final url = Uri.parse(
      'https://script.google.com/macros/s/AKfycbyBLHJZRba0UXgpB_uhspvqZAyhXJghE9i80NlhNkGA7C8Uy2R-7vYcO7px9Lm-TRiV7A/exec',
    );

    final client = http.Client();
    try {
      final request = http.Request('POST', url)
        ..headers['Content-Type'] = 'application/json'
        ..followRedirects = false
        ..body = jsonEncode(data);

      final firstResponse = await client.send(request);

      http.Response response;
      if (firstResponse.statusCode == 302) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Sent!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error sending to sheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      client.close();
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        backgroundColor: Colors.deepPurple.shade700,
        actions: [
          if (isSending)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              setState(() {
                resolt = null;
              });
            },
            icon: Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple.shade700,
      body: Column(
        children: [
          isScanMode && !Platform.isWindows
              ? Expanded(
                  flex: 5,
                  child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
                )
              : Spacer(flex: 3),
          IconButton(
            onPressed: () {
              setState(() {
                isScanMode = !isScanMode;
              });
            },
            icon: Icon(Icons.add_a_photo, color: Colors.black),
            iconSize: 100,
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: (resolt != null)
                  ? Text(
                      'Barcode Type: ${describeEnum(resolt!.format)}\nData: ${resolt!.code}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    )
                  : Text(
                      'Scan a code',
                      style: TextStyle(color: Colors.white70),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
