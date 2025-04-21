import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Expanded(
        child:
            globals.privateKey != null
                ? TestWidget(title: 'test')
                : CreateKeysWidget(title: 'Schlüssel erstellen'),
      ),
    );
  }
}
