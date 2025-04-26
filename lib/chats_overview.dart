import 'package:flutter/material.dart';

class ChatsOverviewWidget extends StatefulWidget {
  const ChatsOverviewWidget({super.key});

  @override
  State<ChatsOverviewWidget> createState() => _ChatsOverviewWidget();
}

class _ChatsOverviewWidget extends State<ChatsOverviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        tooltip: 'Neuen Kontakt hinzufügen',
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
