
import 'package:flutter/material.dart';

class EggProductionReportScreen extends StatelessWidget {
  const EggProductionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Production Report'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Text(
          'Egg Production Report goes here...',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
