import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;
import 'package:nfcommunicator_frontend/util/pointycastle_util.dart';
import 'package:pointycastle/api.dart' as pointycastle;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:sensors_plus/sensors_plus.dart';

class CreateKeysWidget extends StatefulWidget {
  const CreateKeysWidget({super.key, required this.title});
  final String title;

  @override
  State<CreateKeysWidget> createState() => _CreateKeysWidget();
}

class _CreateKeysWidget extends State<CreateKeysWidget> {
  String _collectedEntropy = '';
  String _privateKeyPem = '', _publicKeyPem = '';
  bool _isCompleted = false, _isStarted = false;

  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final Duration sensorInterval = SensorInterval.normalInterval;
  DateTime? _userAccelerometerUpdateTime;
  DateTime? _userGyroscopeUpdateTime;
  static const Duration _ignoreDuration = Duration(milliseconds: 100);
  pointycastle.AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keys;

  void _createKeys() {
    _isStarted = true;
    Timer(const Duration(seconds: 3), () {
      setState(() {
        _abortDataCollection();
        Uint8List bytes = utf8.encode(
          md5.convert(utf8.encode(_collectedEntropy)).toString(),
        );
        keys = generateRSAkeyPair(createSecureRandom(bytes));
      });
      _privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(keys!.privateKey);
      _publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(keys!.publicKey);
      _isStarted = false;
      _isCompleted = true;
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
              _collectedEntropy =
                  '$_collectedEntropy${event.x}${event.y}${event.z}';
              _collectedEntropy = _collectedEntropy.replaceAll(
                RegExp('\\.'),
                '',
              );
              _collectedEntropy = _collectedEntropy.replaceAll(
                RegExp('\\-'),
                '',
              );
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
              _collectedEntropy =
                  '$_collectedEntropy${event.x}${event.y}${event.z}';
              _collectedEntropy = _collectedEntropy.replaceAll(
                RegExp('\\.'),
                '',
              );
              _collectedEntropy = _collectedEntropy.replaceAll(
                RegExp('\\-'),
                '',
              );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      // ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Text(
              'Auf diesem Handy wurden noch keine RSA-Schlüssel gefunden. Diese werden benötigt und Nachrichten sicher zu verschlüsseln.\n\nLassen Sie uns jetzt ein Schlüssel-Paar erstellen!\nDrücken Sie hierzu auf den "Start" Button. Im Anschluss bewegen Sie ihr Handy bitte möglichst zufällig für 10 Sekunden bis Sie einen Ton hören. Schwingen Sie ihr Telefon durch die Luft und machen Sie möglichst zufällige Bewegungen! Die App sammelt in diesem Schritt Zufallsdaten für die erstellung eines möglichst sicheren RSA-Schlüsselpaares.',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_isStarted ? _createKeys : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                child: Text('Start'),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Text(
              'Gesammelte Entropy:',
              textAlign: TextAlign.start,
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
          SizedBox(
            height: 100,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: SingleChildScrollView(child: Text(_collectedEntropy)),
            ),
          ),
          Divider(thickness: 1, height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                        child: Text(
                          'Privater Schlüssel:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: SingleChildScrollView(
                            child: Text(_privateKeyPem),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                        child: Text(
                          'Öffentlicher Schlüssel:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: SingleChildScrollView(
                            child: Text(_publicKeyPem),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      !_isStarted && _isCompleted ? _completeProcess : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                  ),
                  child: Text('Fertigstellen'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _completeProcess() {}
