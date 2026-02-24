
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

void main(){
  runApp(qr_code());
}

class qr_code extends StatefulWidget {
  @override
  _qr_code_state createState() => _qr_code_state();
}

class _qr_code_state extends State<qr_code> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? resolt;
  QRViewController? controller;

    @override
  void reassemble() {
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  
  void _onQRViewCreated(QRViewController controller){
    this.controller = controller;
    controller.scannedDataStream.listen((scanData){
      setState((){
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
        title: const Text('qr code')  
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated)
            ),
          Expanded(
            flex: 5,
          child: Center(
            child: (resolt != null)
              ? Text( 'Barcode Type: ${describeEnum(resolt!.format)}   Data: ${resolt!.code}') : Text('Scan a code')),
          )
        ]
    ),
      );
  }
}