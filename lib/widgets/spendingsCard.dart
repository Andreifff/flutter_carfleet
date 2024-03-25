import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/models/spending.dart';

class SpendingsCard extends StatefulWidget {
  final Car car;
  final Function() onAddSpending;
  final VoidCallback onSpendingAdded;

  const SpendingsCard({
    Key? key,
    required this.car,
    required this.onAddSpending,
    required this.onSpendingAdded,
  }) : super(key: key);

  @override
  _SpendingsCardState createState() => _SpendingsCardState();
}

class _SpendingsCardState extends State<SpendingsCard> {
  List<Spending> spendings = [];
  void _addSpending(Spending newSpending) async {
    await _addSpendingToFirestore(newSpending);
    widget.onSpendingAdded();
  }

  Future<void> _addSpendingToFirestore(Spending newSpending) async {
    try {
      DocumentReference carRef =
          FirebaseFirestore.instance.collection('cars').doc(widget.car.id);

      FirebaseFirestore.instance
          .runTransaction((transaction) async {
            DocumentSnapshot carSnapshot = await transaction.get(carRef);

            if (!carSnapshot.exists) {
              throw Exception("Car does not exist!");
            }

            var carData = carSnapshot.data() as Map<String, dynamic>;
            List<dynamic> currentSpendings =
                List.from(carData['spendings'] ?? []);

            // Adding the new spending to the current list of spendings
            currentSpendings.add(newSpending.toJson());

            // Updating the car document with the new list of spendings
            transaction.update(carRef, {'spendings': currentSpendings});
          })
          .then((_) => widget
              .onSpendingAdded()) // Ensure to call the refresh callback after updating Firestore.
          .catchError((e) {
            print("Error adding spending: $e");
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to add spending. Please try again.')));
          });
    } catch (e) {
      print("Error outside transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add spending. Please try again.')));
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize the spendings list from the car object
    spendings = widget.car.spendings;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spendings', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .doc(widget.car.id)
                  .collection('spendings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> docs = snapshot.data!.docs;
                List<Spending> spendings = docs
                    .map((doc) => Spending.fromFirestore(
                        doc.data() as Map<String, dynamic>))
                    .toList();

                if (spendings.isEmpty) {
                  return ElevatedButton(
                    onPressed: widget.onAddSpending,
                    child: Text('Add First Spending'),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: spendings.length,
                    itemBuilder: (context, index) {
                      Spending spending = spendings[index];
                      return ListTile(
                        title: Text(
                            '${spending.category}: \$${spending.amount.toStringAsFixed(2)}'),
                        subtitle: Text(
                            'Odometer: ${spending.odometer} ${spending.currency}, Date: ${DateFormat('yyyy-MM-dd').format(spending.date)}'),
                      );
                    },
                  );
                }
              },
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: widget.onAddSpending,
              child: Text('Add More Spending'),
            ),
          ],
        ),
      ),
    );
  }

  double calculateTotalSpendings() {
    return spendings.fold(0, (sum, item) => sum + item.amount);
  }
}
