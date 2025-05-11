import 'dart:async';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nfcommunicator_frontend/home_page_widget.dart';
import 'package:nfcommunicator_frontend/models/user_data.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;
import 'package:nfcommunicator_frontend/util/nfcommunicator_repository.dart';
import 'package:nfcommunicator_frontend/util/pointycastle_util.dart';
import 'package:nfcommunicator_frontend/util/sqllite_database_util.dart';
import 'package:pointycastle/api.dart' as pointycastle;
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
  bool _isCompleted = false,
      _isStarted = false,
      _isGeneratingKeys = false,
      _isGettingUserId = false;

  final TextEditingController _textFieldController = TextEditingController();
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final Duration sensorInterval = SensorInterval.normalInterval;
  DateTime? _userAccelerometerUpdateTime;
  DateTime? _userGyroscopeUpdateTime;
  static const Duration _ignoreDuration = Duration(milliseconds: 100);
  pointycastle.AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? keys;

  void _createKeys() {
    _isStarted = true;
    Timer(const Duration(seconds: 3), () async {
      setState(() {
        _isGeneratingKeys = true;
      });
      _abortDataCollection();
      final Map<String, String> keyMap =
          await PointycastleUtil.generateRSAkeyPair(_collectedEntropy);
      setState(() {
        _privateKeyPem = keyMap[globals.keystoreKPrivateKeyKey]!;
        _publicKeyPem = keyMap[globals.keystorePublicKeyKey]!;
        _isGeneratingKeys = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: Text('Schlüssel erfolgreich erstellt'),
                content: Text(
                  'Die Schlüssel wurden erfolgreich erstellt. Sie können sich jetzt die erstellten Schlüssel anschauen. Sie müssen sich diese aber natürlich nicht merken. Sobald Sie fertig sind bestätigen Sie den Prozess mit "Fertigstellen".',
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Ok'),
                    child: const Text('Ok'),
                  ),
                ],
              ),
        );
      }
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

  void _completeProcess() async {
    try {
      if (_privateKeyPem.isEmpty || _publicKeyPem.isEmpty) {
        throw 'At least one key was null. Something went wrong';
      }
      setState(() {
        _isGettingUserId = true;
      });
      final userId = await NFCommunicatorRepository().getUserId();
      if (userId < 0) throw "Retrieved UserId was < 0. Something is off";
      setState(() {
        _isGettingUserId = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                'Jetzt fehlt nur noch ihr Benutzername. Dieser Name wird anderen Nutzern standardmäßig angezeigt wenn diese Sie als Kontakt hinzufügen.',
              ),
              content: TextField(
                controller: _textFieldController,
                decoration: InputDecoration(hintText: "Text Field in Dialog"),
              ),
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                  ),
                  onPressed: () async {
                    final userData = UserData(
                      userId: userId,
                      userName: _textFieldController.text,
                    );
                    final dbHelper = DatabaseHelper();
                    var insertedId = await dbHelper.insertUserData(userData);
                    if (insertedId != userId) throw 'Unable to insert UserData';
                    final storage = FlutterSecureStorage();
                    await storage.write(
                      key: globals.keystoreKPrivateKeyKey,
                      value: _privateKeyPem,
                    );
                    await storage.write(
                      key: globals.keystorePublicKeyKey,
                      value: _publicKeyPem,
                    );
                    final route = MaterialPageRoute(
                      builder:
                          (context) => HomePageWidget(title: 'NF-Communicator'),
                    );
                    if (context.mounted) {
                      Navigator.push(context, route);
                    }
                  },
                  child:
                      !_isGettingUserId ? Text('OK') : Text('Bitte warten...'),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isGettingUserId = false;
        });
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

  void _abortDataCollection() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext conx) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
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
            height: 70,
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
                        padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                        child: Text(
                          'Privater Schlüssel:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      !_isGeneratingKeys
                          ? Expanded(
                            child: SingleChildScrollView(
                              child: Text(_privateKeyPem),
                            ),
                          )
                          : SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.width / 4,
                            child: CircularProgressIndicator(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
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
                        padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                        child: Text(
                          'Öffentlicher Schlüssel:',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      !_isGeneratingKeys
                          ? Expanded(
                            child: SingleChildScrollView(
                              child: Text(_publicKeyPem),
                            ),
                          )
                          : SizedBox(
                            width: MediaQuery.of(context).size.width / 4,
                            height: MediaQuery.of(context).size.width / 4,
                            child: CircularProgressIndicator(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: SingleChildScrollView(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompleted ? _completeProcess : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                  ),
                  child:
                      !_isGettingUserId
                          ? Text('Fertigstellen')
                          : Text('Bitte warten...'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
