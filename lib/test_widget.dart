import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:nfcommunicator_frontend/util/pointycastle_util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:basic_utils/basic_utils.dart' as basic_utils;

class TestWidget extends StatefulWidget {
  const TestWidget({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TestWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<TestWidget> {
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final Duration sensorInterval = SensorInterval.normalInterval;
  DateTime? _userAccelerometerUpdateTime;
  DateTime? _userGyroscopeUpdateTime;
  static const Duration _ignoreDuration = Duration(milliseconds: 100);
  String _entropyCleaned = "";
  final messageToEncryptTextController = TextEditingController();
  String _debugString = "Debug-Messages:\n\n";
  bool _buttonEnabled = true;
  pointycastle.AsymmetricKeyPair<
    pointycastle.RSAPublicKey,
    pointycastle.RSAPrivateKey
  >?
  keys;
  static const String KEYSTORE_KEY = "NFCommunicatorKeys";

  @override
  void dispose() {
    super.dispose();
    messageToEncryptTextController.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  void _checkKeystore() async {
    final storage = FlutterSecureStorage();
    String? pem = await storage.read(key: KEYSTORE_KEY);
    if (pem != null) {
      setState(() {
        _debugString = '$_debugString PEM read from keystore\n\n$pem”';
      });
    }
  }

  void _collectEntropyAndGenerateKeys() {
    _buttonEnabled = false;
    _entropyCleaned = "";
    //starting a timer and handling processing of the collected entropy
    Timer(const Duration(seconds: 5), () {
      setState(() {
        _debugString = '$_debugString Entropy collection complete!\n\n';
        _abortDataCollection();
        Uint8List bytes = utf8.encode(
          md5.convert(utf8.encode(_entropyCleaned)).toString(),
        );
        _debugString =
            '$_debugString Created md5 of entropy string and parsed to bytes!\n\n';
        keys = generateRSAkeyPair(createSecureRandom(bytes));
        _debugString = '$_debugString RSA Keypair generated!\n\n';
        Uint8List encryptedMessage = rsaEncrypt(
          keys!.publicKey,
          utf8.encode(messageToEncryptTextController.text),
        );
        _debugString = '$_debugString Encrypted the message!\n\n';
        Uint8List signature = rsaSign(keys!.privateKey, encryptedMessage);
        _debugString = '$_debugString Sign!d the message!\n\n';
        Uint8List unsignedGarbageMessage = utf8.encode("garbetest");
        if (rsaVerify(keys!.publicKey, encryptedMessage, signature)) {
          _debugString =
              '$_debugString Message signature verified successfully!\n\n';
        } else {
          _debugString = '$_debugString Message has invalid signature!\n\n';
        }
        Uint8List decryptedBytes = rsaDecrypt(
          keys!.privateKey,
          encryptedMessage,
        );
        String decryptedMessage = utf8.decode(decryptedBytes);
        _debugString =
            '$_debugString Message decrypted successfully! Message is: $decryptedMessage\n\n';
      });
      _buttonEnabled = true;
    });
    //listening for accelerator data
    _streamSubscriptions.add(
      userAccelerometerEventStream(samplingPeriod: sensorInterval).listen((
        UserAccelerometerEvent event,
      ) {
        final now = event.timestamp;
        setState(() {
          if (_userAccelerometerUpdateTime != null) {
            final interval = now.difference(_userAccelerometerUpdateTime!);
            if (interval > _ignoreDuration) {
              _entropyCleaned =
                  '$_entropyCleaned${event.x}${event.y}${event.z}';
              _entropyCleaned = _entropyCleaned.replaceAll(RegExp('\\.'), '');
              _entropyCleaned = _entropyCleaned.replaceAll(RegExp('\\-'), '');
            }
          }
        });
        _userAccelerometerUpdateTime = now;
      }),
    );
    //Listening for gyroscope data
    _streamSubscriptions.add(
      gyroscopeEventStream(samplingPeriod: sensorInterval).listen((
        GyroscopeEvent event,
      ) {
        final now = event.timestamp;
        setState(() {
          if (_userGyroscopeUpdateTime != null) {
            final interval = now.difference(_userGyroscopeUpdateTime!);
            if (interval > _ignoreDuration) {
              _entropyCleaned =
                  '$_entropyCleaned${event.x}${event.y}${event.z}';
              _entropyCleaned = _entropyCleaned.replaceAll(RegExp('\\.'), '');
              _entropyCleaned = _entropyCleaned.replaceAll(RegExp('\\-'), '');
            }
          }
        });
        _userGyroscopeUpdateTime = now;
      }),
    );
  }

  void _abortDataCollection() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  void _clearDebugString() {
    setState(() {
      _entropyCleaned = "";
      _debugString = "Debug-Messages:\n\n";
    });
  }

  void _storeKeys() async {
    final storage = FlutterSecureStorage();
    String test = basic_utils.CryptoUtils.encodeRSAPrivateKeyToPem(
      keys!.privateKey,
    );
    await storage.write(key: KEYSTORE_KEY, value: test);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              onPressed: _buttonEnabled ? _collectEntropyAndGenerateKeys : null,
              child: Text("Collect entropy and generate keys"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              onPressed: _clearDebugString,
              child: Text("Clear debug"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              onPressed: _checkKeystore,
              child: Text("Check Keystore"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                elevation: 0,
              ),
              onPressed: _storeKeys,
              child: Text("Store in Keystore"),
            ),
            Divider(color: Colors.black, thickness: 2),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a message to sign and encrypt.',
              ),
              controller: messageToEncryptTextController,
            ),
            Divider(color: Colors.black, thickness: 2),
            Expanded(child: SingleChildScrollView(child: Text(_debugString))),
          ],
        ),
      ),
    );
  }
}
