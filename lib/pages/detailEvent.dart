import 'package:flutter/material.dart';

class DetailEvent extends StatelessWidget {
  const DetailEvent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Details of the Event will be shown here.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
