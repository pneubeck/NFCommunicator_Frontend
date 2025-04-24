import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nfcommunicator_frontend/create_keys_widget.dart';
import 'package:nfcommunicator_frontend/test_widget.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Expanded(
        child: FutureBuilder(
          future: _getKeys(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Expanded(
                child:
                    globals.privateKey != null
                        ? TestWidget(title: 'test')
                        : CreateKeysWidget(title: 'Schlüssel erstellen'),
              );
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
