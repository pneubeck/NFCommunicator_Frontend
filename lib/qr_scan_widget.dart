import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanWidget extends StatefulWidget {
  const QrScanWidget({super.key});

  @override
  State<QrScanWidget> createState() => _QrScanWidget();
}

class _QrScanWidget extends State<QrScanWidget> {
  bool _dataScanned = false;

  void _onDetected(BarcodeCapture result) {
    try {
      setState(() {
        _dataScanned = true;
      });
      var scannedString = result.barcodes.first.rawValue;
      if (scannedString == null || scannedString.isEmpty) {
        throw 'Scanned data was null... something is off.';
      }
      List<String> contactData = scannedString.split('|');
      if (contactData.length != 3) {
        throw 'Invalid number of sections in scanned string... something is off.';
      }
      var scannedUserId = contactData[0];
      var scannedUserName = contactData[1];
      var scannedPublicKey = CryptoUtils.rsaPublicKeyFromPem(contactData[2]);
    } catch (error) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('Fehler'),
                content: Text(
                  'Die Aktion konnte nicht abgeschlossen werden. Versuchen Sie es später erneut\nDer Fehler war:\n$error',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ok'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: Expanded(
        child:
            !_dataScanned
                ? MobileScanner(
                  onDetect: (result) {
                    _onDetected(result);
                  },
                )
                : CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
      ),
    );
  }
}
