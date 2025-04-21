import 'package:flutter/material.dart';
import 'package:nfcommunicator_frontend/util/globals.dart' as globals;

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
              child: Expanded(
                child: ElevatedButton(
                  onPressed: !_isStarted ? _createKeys : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                  ),
                  child: Text('Start'),
                ),
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
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: SingleChildScrollView(
              child: Text(_collectedEntropy, maxLines: 5),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5 - 0.5,
                  child: Expanded(
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
                        Padding(
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: SingleChildScrollView(
                            child: Text(_privateKeyPem),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5 - 0.5,
                  child: Expanded(
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
                        Padding(
                          padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
                          child: SingleChildScrollView(
                            child: Text(_publicKeyPem),
                          ),
                        ),
                      ],
                    ),
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
                child: Expanded(
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
          ),
        ],
      ),
    );
  }
}

void _createKeys() {}

void _completeProcess() {}
