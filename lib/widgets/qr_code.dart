import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        resolt = scanData;
      });
      // automatically open any http/https URLs
      _maybeLaunchResult();
    });
  }

  void openQrCode() {
    // exposed method to manually open the current scan result
    if (resolt != null && resolt!.code != null) {
      final code = resolt!.code!;
      if (code.startsWith('http')) {
        _launchUrl(code);
      }
    }
  }

  void _maybeLaunchResult() {
    if (resolt != null && resolt!.code != null) {
      final code = resolt!.code!;
      if (code.startsWith(RegExp(r'https?://'))) {
        // once we attempt to open, pause to avoid repeated launches
        controller?.pauseCamera();
        _launchUrl(code);
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
    }
  }

  Future<void> flipeCmera() async {
    await controller?.flipCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('qr code')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: (resolt != null)
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Barcode Type: ${describeEnum(resolt!.format)}   Data: ${resolt!.code}',
                        ),
                        if (resolt!.code != null &&
                            resolt!.code!.startsWith(RegExp(r'https?://')))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                openQrCode();
                              },
                              child: const Text('Open Link'),
                            ),
                          ),
                        if (controller != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton(
                              onPressed: () {
                                controller?.resumeCamera();
                              },
                              child: const Text('Scan Again'),
                            ),
                          ),
                      ],
                    )
                  : const Text('Scan a code'),
            ),
          ),
        ],
      ),
    );
  }
}
