import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

void main() {
  runApp(MaterialApp(home: QRCode(), debugShowCheckedModeBanner: false));
}

class QRCode extends StatefulWidget {
  @override
  QRCodeState createState() => QRCodeState();
}

class QRCodeState extends State<QRCode> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? resolt;
  QRViewController? controller;
  bool isScanMode = false;

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
    });
  }

  Future<void> flipeCmera() async {
    await controller?.flipCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        backgroundColor: Colors.deepPurple.shade700,
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
                      'Barcode Type: ${describeEnum(resolt!.format)}   Data: ${resolt!.code}',
                    )
                  : Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }
}
