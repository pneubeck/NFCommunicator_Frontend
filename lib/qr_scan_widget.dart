import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfcommunicator_frontend/home_page_widget.dart';
import 'package:nfcommunicator_frontend/models/contact.dart';
import 'package:nfcommunicator_frontend/util/sqllite_database_util.dart';

class QrScanWidget extends StatefulWidget {
  const QrScanWidget({super.key});

  @override
  State<QrScanWidget> createState() => _QrScanWidget();
}

class _QrScanWidget extends State<QrScanWidget> {
  bool _dataScanned = false;

  void _onDetected(BarcodeCapture result) async {
    if (_dataScanned) return;
    _dataScanned = true;
    try {
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
      var scannedPublicKey = contactData[2];
      final dbHelper = DatabaseHelper();
      final contact = Contact(
        userId: int.parse(scannedUserId),
        userName: scannedUserName,
        publicKeyPem: scannedPublicKey,
      );
      await dbHelper.insertContact(contact);
      final route = MaterialPageRoute(
        builder: (context) => HomePageWidget(title: 'NF-Communicator'),
      );
      if (context.mounted) {
        Navigator.push(context, route);
      }
      //Navigator.pop(context);
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
      body: MobileScanner(
        onDetect: (result) {
          _onDetected(result);
        },
      ),
    );
  }
}
