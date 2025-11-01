// lib/screens/lighting_program_screen.dart

import 'package:flutter/material.dart';

class LightingProgramScreen extends StatelessWidget {
  const LightingProgramScreen({super.key});

  Widget _buildScheduleRow(String period, String lightDuration, String notes, {bool isHeader = false}) {
    if (isHeader) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.deepOrange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: const [
            Expanded(
              flex: 2,
              child: Text(
                "Period (Age)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "Light Hours",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                "Purpose",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              period,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lightDuration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              notes,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Layer Lighting Program'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "A well-managed lighting program is crucial for stimulating and maintaining high egg production.\n\nThis schedule is optimized for tropical regions like Zambia.",
                  style: TextStyle(fontSize: 15.5, color: Colors.grey.shade800, fontStyle: FontStyle.italic, height: 1.4),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildScheduleRow("", "", "", isHeader: true),
          _buildScheduleRow("Day 1 - 3", "23 Hours", "Help chicks find food and water."),
          _buildScheduleRow("Day 4 - 7", "20 Hours", "Gradual step-down."),
          _buildScheduleRow("Week 2 (Day 8-14)", "18 Hours", "Continued step-down."),
          _buildScheduleRow("Week 3 (Day 15-21)", "16 Hours", "Preparing for grower phase."),
          _buildScheduleRow("Week 4 - 18", "12 Hours", "Hold at natural daylight hours."),
          _buildScheduleRow("Week 19 (Day 127)", "13 Hours", "Begin light stimulation."),
          _buildScheduleRow("Week 20 (Day 134)", "14 Hours", "Continue gradual stimulation."),
          _buildScheduleRow("Week 21 (Day 141)", "15 Hours", "Approaching point of lay."),
          _buildScheduleRow("Week 22 (Day 148)", "15.5 Hours", "Final push before peak production."),
          _buildScheduleRow("Week 23 (Day 155)", "16 Hours", "Entering peak production."),
          _buildScheduleRow("Week 24 (Day 169)", "16.5 Hours", "Achieving peak light duration."),
          _buildScheduleRow("Week 25 - 85+", "16.5 - 17 Hours", "Maintain for rest of productive life."),
        ],
      ),
    );
  }
}
