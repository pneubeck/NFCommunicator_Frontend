import 'package:flutter/material.dart';
import 'package:nfcommunicator_frontend/home_page_widget.dart';

void main() async {
  runApp(const MyApp());
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
