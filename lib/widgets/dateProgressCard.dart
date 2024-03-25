import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateProgressCard extends StatefulWidget {
  final String title;
  final DateTime? initialExpiryDate;
  final Function(DateTime) onUpdate;

  DateProgressCard({
    Key? key,
    required this.title,
    required this.initialExpiryDate,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _DateProgressCardState createState() => _DateProgressCardState();
}

class _DateProgressCardState extends State<DateProgressCard> {
  DateTime? expiryDate;

  @override
  void initState() {
    super.initState();
    expiryDate = widget
        .initialExpiryDate; // Initialize expiryDate with the initial value
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != expiryDate) {
      setState(() {
        expiryDate = picked;
        widget.onUpdate(picked); // Notify the parent widget of the update
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //final dateFormat = DateFormat('yyyy-MM-dd'); // Define your preferred format
    final dateFormat = DateFormat('dd-MM-yyyy');
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
    Color progressColor =
        progress >= 0.8 ? Colors.red : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 4.0),
            if (expiryDate != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Adjust as needed for layout
                children: [
                  Text("Expiry Date: ${dateFormat.format(expiryDate!)}"),
                  Text("${daysLeft > 0 ? daysLeft : 0} days left"),
                ],
              ),
              SizedBox(height: 4.0),
              SizedBox(
                height: 8.0,
                child: LinearProgressIndicator(
                  value: progress,
                  color:
                      progressColor, // Use the dynamic color based on progress
                  backgroundColor: progressColor.withOpacity(0.3),
                ),
              ),
              SizedBox(height: 4.0),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text('Update'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text('Set ${widget.title} Date'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
