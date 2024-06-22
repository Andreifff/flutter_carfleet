import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/models/spending.dart';

class SpendingsCard extends StatefulWidget {
  final Car car;
  final Function() onAddSpending;
  final VoidCallback onSpendingAdded;
  final Function(String, Spending) onUpdateSpending;
  final Function(String) onDeleteSpending;
  final String selectedCurrency;

  const SpendingsCard({
    Key? key,
    required this.car,
    required this.onAddSpending,
    required this.onSpendingAdded,
    required this.onUpdateSpending,
    required this.onDeleteSpending,
    required this.selectedCurrency,
  }) : super(key: key);

  @override
  _SpendingsCardState createState() => _SpendingsCardState();
}

class _SpendingsCardState extends State<SpendingsCard> {
  List<Spending> spendings = [];
  //For sorting
  bool sortByDate = true; // true for date, false for cost
  bool sortAscending = true; // true for ascending, false for descending
  @override
  void initState() {
    super.initState();
    // Initialize the spendings list from the car object
    spendings = widget.car.spendings;
  }

  void _addSpending(Spending newSpending) async {
    await _addSpendingToFirestore(newSpending);
    widget.onSpendingAdded();
  }

  Future<void> _deleteSpending(String spendingId, int index) async {
    final bool confirmDeletion = await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Delete Spending'),
            content:
                const Text('Are you sure you want to delete this spending?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDeletion) {
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.car.id)
          .collection('spendings')
          .doc(spendingId)
          .delete();
    }
  }

  // Future<void> _addSpendingToFirestore(Spending newSpending) async {
  //   try {
  //     DocumentReference carRef =
  //         FirebaseFirestore.instance.collection('cars').doc(widget.car.id);

  //     FirebaseFirestore.instance
  //         .runTransaction((transaction) async {
  //           DocumentSnapshot carSnapshot = await transaction.get(carRef);

  //           if (!carSnapshot.exists) {
  //             throw Exception("Car does not exist!");
  //           }

  //           var carData = carSnapshot.data() as Map<String, dynamic>;
  //           List<dynamic> currentSpendings =
  //               List.from(carData['spendings'] ?? []);

  //           // Adding the new spending to the current list of spendings
  //           currentSpendings.add(newSpending.toJson());

  //           // Updating the car document with the new list of spendings
  //           transaction.update(carRef, {'spendings': currentSpendings});
  //         })
  //         .then((_) => widget
  //             .onSpendingAdded()) // Ensure to call the refresh callback after updating Firestore.
  //         .catchError((e) {
  //           print("Error adding spending: $e");
  //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //               content: Text('Failed to add spending. Please try again.')));
  //         });
  //   } catch (e) {
  //     print("Error outside transaction: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to add spending. Please try again.')));
  //   }
  // }
  Future<void> _addSpendingToFirestore(Spending newSpending) async {
    try {
      Spending spendingWithSelectedCurrency = Spending(
        id: newSpending.id,
        category: newSpending.category,
        amount: newSpending.amount,
        odometer: newSpending.odometer,
        currency: widget.selectedCurrency,
        date: newSpending.date,
      );

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
            currentSpendings.add(spendingWithSelectedCurrency.toJson());
            transaction.update(carRef, {'spendings': currentSpendings});
          })
          .then((_) => widget.onSpendingAdded())
          .catchError((e) {
            print("Error adding spending: $e");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Failed to add spending. Please try again.')));
          });
    } catch (e) {
      print("Error outside transaction: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to add spending. Please try again.')));
    }
  }

  void sortSpendings() {
    // Create a mutable copy of the spendings list
    List<Spending> mutableSpendings = List.from(spendings);

    if (sortByDate) {
      mutableSpendings.sort((a, b) {
        return sortAscending
            ? a.date.compareTo(b.date)
            : b.date.compareTo(a.date);
      });
    } else {
      mutableSpendings.sort((a, b) {
        return sortAscending
            ? a.amount.compareTo(b.amount)
            : b.amount.compareTo(a.amount);
      });
    }

    // Update the state with the sorted list
    setState(() {
      spendings = mutableSpendings;
    });
  }

  Widget sortOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              sortByDate = !sortByDate;
              sortSpendings();
            });
          },
          child: Text(sortByDate ? 'Sort by Cost' : 'Sort by Date'),
        ),
        IconButton(
          icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
          onPressed: () {
            setState(() {
              sortAscending = !sortAscending;
              sortSpendings();
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Adjusting layout for 'Expenses' and sort options to be in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Expenses',
                      style: Theme.of(context).textTheme.headline6),
                ),
                sortOptions(),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cars')
                  .doc(widget.car.id)
                  .collection('spendings')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                List<DocumentSnapshot> docs = snapshot.data!.docs;

                List<Spending> sortedSpendings = docs
                    .map((doc) => Spending.fromFirestore(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .toList();

                if (sortByDate) {
                  sortedSpendings.sort((a, b) {
                    return sortAscending
                        ? a.date.compareTo(b.date)
                        : b.date.compareTo(a.date);
                  });
                } else {
                  sortedSpendings.sort((a, b) {
                    return sortAscending
                        ? a.amount.compareTo(b.amount)
                        : b.amount.compareTo(a.amount);
                  });
                }

                if (sortedSpendings.isEmpty) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: widget.onAddSpending,
                      child: const Text('Add First Spending'),
                    ),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: sortedSpendings.length,
                    itemBuilder: (context, index) {
                      Spending spending = sortedSpendings[index];
                      return ListTile(
                        title: Text(
                            '${spending.category}: ${spending.amount.toStringAsFixed(2)} ${spending.currency}'),
                        subtitle: Text(
                            'Odometer: ${spending.odometer} Km, Date: ${DateFormat('yyyy-MM-dd').format(spending.date)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => widget.onUpdateSpending(
                                  docs[index].id, spending),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () =>
                                  widget.onDeleteSpending(docs[index].id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: widget.onAddSpending,
                child: const Text('Add More Spending'),
              ),
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
