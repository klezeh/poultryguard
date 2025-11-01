
import 'package:flutter/material.dart';

class FeedEfficiencyScreen extends StatelessWidget {
  const FeedEfficiencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed Efficiency'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Text(
          'Feed Efficiency metrics and analysis will appear here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
