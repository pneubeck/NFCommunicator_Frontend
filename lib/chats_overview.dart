import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nfcommunicator_frontend/qr_scan_widget.dart';
import 'package:nfcommunicator_frontend/util/sqllite_database_util.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;

class ChatsOverviewWidget extends StatefulWidget {
  const ChatsOverviewWidget({super.key});

  @override
  State<ChatsOverviewWidget> createState() => _ChatsOverviewWidget();
}

class _ChatsOverviewWidget extends State<ChatsOverviewWidget> {
  void _showInitialAddContactDialog() async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('Was möchten Sie tun?'),
                content: Text(
                  'Möchten Sie selbst einen Kontakt hinzufügen oder möchten Sie einem Freund erlauben Sie als Kontakt hinzuzufügen?',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _scanQrCode();
                    },
                    child: const Text('Selbst einen Freund hinzufügen'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showUserDataDialog();
                    },
                    child: const Text(
                      'Von einem Freund als Kontakt hinzufügen lassen',
                    ),
                  ),
                ],
              ),
        );
      }
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

  void _scanQrCode() {
    final route = MaterialPageRoute(builder: (context) => QrScanWidget());
    if (context.mounted) {
      Navigator.push(context, route);
    }
  }

  void _showUserDataDialog() async {
    try {
      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getUserData();
      final secureStorage = FlutterSecureStorage();
      final publicKeyPem = await secureStorage.read(
        key: globals.keystorePublicKeyKey,
      );
      var qrCodeData = '${userData.userId}|${userData.userName}|$publicKeyPem';
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('Lassen Sie ihren Freund den QR-Code scannen.'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width - 130,
                  height: MediaQuery.of(context).size.width - 130,
                  child: QrImageView(
                    data: qrCodeData,
                    version: QrVersions.auto,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fertig'),
                  ),
                ],
              ),
        );
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        tooltip: 'Neuen Kontakt hinzufügen',
        onPressed: _showInitialAddContactDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
