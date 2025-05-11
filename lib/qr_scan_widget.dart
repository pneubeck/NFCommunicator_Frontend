import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanWidget extends StatefulWidget {
  const QrScanWidget({super.key});

  @override
  State<QrScanWidget> createState() => _QrScanWidget();
}

class _QrScanWidget extends State<QrScanWidget> {
  void _onDetected(BarcodeCapture result) {
    print(result.barcodes.first.rawValue);
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: Expanded(
        child: MobileScanner(
          onDetect: (result) {
            _onDetected(result);
          },
        ),
      ),
    );
  }
}
