import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateProgressCard extends StatelessWidget {
  final String title;
  final DateTime? expiryDate;
  final Function(DateTime) onUpdate;
  final Function() onDateUpdated; // Add this callback

  DateProgressCard({
    Key? key,
    required this.title,
    this.expiryDate,
    required this.onUpdate,
    required this.onDateUpdated, // Initialize in constructor
  }) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onUpdate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd'); // Define your preferred format
    final currentDate = DateTime.now();
    double progress = 0.0;
    int daysLeft = 0;

    if (expiryDate != null) {
      daysLeft = expiryDate!.difference(currentDate).inDays;
      final totalDuration =
          365; // Assuming a year-long period; adjust as needed
      progress = daysLeft > 0 ? (1 - daysLeft / totalDuration) : 1.0;
      progress = progress.clamp(0.0, 1.0); // Ensure progress is between 0 and 1
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 4.0),
            if (expiryDate != null) ...[
              Text("Expiry Date: ${dateFormat.format(expiryDate!)}"),
              SizedBox(height: 4.0),
              LinearProgressIndicator(value: progress),
              SizedBox(height: 4.0),
              Text("${daysLeft > 0 ? daysLeft : 0} days left"),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                //child: Text('Update $title Date'),
                child: Text('Update'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text('Set $title Date'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
