import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nfcommunicator_frontend/home_page_widget.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;

void main() async {
  runApp(const MyApp());
  var storage = FlutterSecureStorage();
  String? privateKeyPem = await storage.read(
    key: globals.keystoreKPrivateKeyKey,
  );
  String? publicKeyPem = await storage.read(key: globals.keystorePublicKeyKey);
  if (privateKeyPem != null && publicKeyPem != null) {
    globals.privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
    globals.publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 51, 214, 18),
        ),
      ),
      home: const HomePageWidget(title: 'NF-Communicator'),
    );
  }
}
