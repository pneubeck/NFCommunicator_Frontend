import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nfcommunicator_frontend/chats_overview.dart';
import 'package:nfcommunicator_frontend/create_keys_widget.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;
import 'package:nfcommunicator_frontend/util/sqllite_database_util.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key, required this.title});
  final String title;

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  Future _getKeys() async {
    final storage = FlutterSecureStorage();
    String? privatekeyPem = await storage.read(
      key: globals.keystoreKPrivateKeyKey,
    );
    String? publickeyPem = await storage.read(
      key: globals.keystorePublicKeyKey,
    );
    if (privatekeyPem != null &&
        privatekeyPem.isNotEmpty &&
        publickeyPem != null &&
        publickeyPem.isNotEmpty) {
      globals.privateKey = CryptoUtils.rsaPrivateKeyFromPem(privatekeyPem);
      globals.publicKey = CryptoUtils.rsaPublicKeyFromPem(publickeyPem);
      return true;
    }
    return false;
  }

  void _resetRsaKeys() async {
    final storage = FlutterSecureStorage();
    await storage.delete(key: globals.keystoreKPrivateKeyKey);
    await storage.delete(key: globals.keystorePublicKeyKey);
    setState(() {
      globals.privateKey = null;
      globals.publicKey = null;
    });
  }

  void _showSavedUserData() async {
    try {
      final dbHelper = DatabaseHelper();
      final userData = await dbHelper.getUserData();
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('UserData'),
                content: Text(
                  'Benutzername: ${userData.userName}\nUserId: ${userData.userId}',
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
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Debug Optionen')),
            ListTile(title: Text('Reset RSA Keys'), onTap: _resetRsaKeys),
            ListTile(
              title: Text('Show saved UserData'),
              onTap: _showSavedUserData,
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _getKeys(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (globals.privateKey != null) {
              return ChatsOverviewWidget();
            } else {
              return CreateKeysWidget(title: 'Schlüssel erstellen');
            }
          }
          return Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.width / 2,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}
