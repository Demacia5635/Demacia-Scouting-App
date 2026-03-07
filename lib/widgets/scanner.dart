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

    return {
      'enter ur team station':                  parts.length > 0  ? parts[0]  : '',
      'enter your name':                        parts.length > 1  ? parts[1]  : '',
      'enter your match team':                  parts.length > 2  ? parts[2]  : '',
      'enter your match number':                parts.length > 3  ? parts[3]  : '',
      'Auto_how many scored fuel':              parts.length > 4  ? parts[4]  : '',
      'Auto_how many fuel got to their side':   parts.length > 5  ? parts[5]  : '',
      'label':                                  parts.length > 6  ? parts[6]  : '',
      'teleop_how many scored fuel':            parts.length > 7  ? parts[7]  : '',
      'teleop_how many fuel got to their side': parts.length > 8  ? parts[8]  : '',
      'climb':                                  parts.length > 9  ? parts[9]  : '',
      'defence0-5':                             parts.length > 10 ? parts[10] : '',
    };
  }

  Future<void> flipeCmera() async {
    await controller?.flipCamera();
  }

  Future<void> sendToSheet(Map<String, dynamic> data) async {
    setState(() => isSending = true);

    final url = Uri.parse(
      'https://script.google.com/macros/s/AKfycbzwDCPVAost-Crrql2l6CiGi8C5KUmH0ZFE6UBmFASLsN-l9mlzeOMrpbwlyD7LVM4svg/exec',
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
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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
          isScanMode
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