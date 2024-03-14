import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/car.dart'; // Update this import path as necessary
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/widgets/dateProgressCard.dart';
import 'package:intl/intl.dart';

class CarDetailsScreen extends StatefulWidget {
  final Car car;

  const CarDetailsScreen({Key? key, required this.car}) : super(key: key);

  @override
  _CarDetailsScreenState createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  Car? updatedCar; // Holds the updated car details
  late Car _car;
  Car? _editableCar; // A mutable copy of the car
  @override
  void initState() {
    super.initState();
    updatedCar = widget.car; // Initial car details
    _editableCar = widget.car;
  }

  Future<void> updateCarDetailsInFirestore(String field, dynamic value) async {
    await FirebaseFirestore.instance
        .collection('cars')
        .doc(_editableCar!.id)
        .update({
      field: value,
    });

    // After Firestore update, refresh local editable copy to reflect changes
    _refreshEditableCar();
  }

  Future<void> _refreshEditableCar() async {
    // Fetch the updated car details from Firestore
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(_editableCar!.id)
        .get();
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

    if (data != null) {
      setState(() {
        // Pass both the data and the document ID to the fromFirestore method
        _editableCar = Car.fromFirestore(data, snapshot.id);
      });
    }
  }

  void _showEditMakeDialog() async {
    final TextEditingController controller =
        TextEditingController(text: _editableCar?.make);
    final String? newMake = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Make'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter car's new make"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(
                context,
              ).pop(),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );

    if (newMake != null && newMake != _editableCar?.make) {
      await updateCarDetailsInFirestore('make', newMake);
      _refreshEditableCar();
    }
  }

  Widget _buildMakeEditField() {
    return Row(
      children: [
        Expanded(
          child: Text(
              'Make: ${_editableCar?.make ?? 'N/A'}'), // Displays the car make
        ),
        IconButton(
          icon: Icon(Icons.edit), // The edit icon
          onPressed: _showEditMakeDialog, // Calls the dialog when tapped
        ),
      ],
    );
  }

  Future<void> deleteCar(BuildContext context, String carId) async {
    if (carId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
        Navigator.pop(context, true); // Navigate back after successful deletion
      } catch (e) {
        print("Error deleting car: $e");
        // Optionally, show a snackbar or dialog to inform the user of the error
      }
    } else {
      print("Car ID is empty, cannot delete car.");
      // Handle case where car ID is somehow empty
    }
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      updateCarDate(field, picked);
    }
  }

  Future<void> updateCarDate(String field, DateTime date) async {
    // Update local state immediately for a responsive UI
    DateTime? previousValue;
    setState(() {
      previousValue = getFieldDate(field);
      setFieldDate(field, date);
    });

    try {
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(_editableCar?.id)
          .update({
        field: Timestamp.fromDate(date),
      });
      // Optional: Confirm update or refetch details if necessary
      print("Date updated successfully in Firestore.");
    } catch (e) {
      print("Error updating date in Firestore: $e");
      // Revert to previous value if Firestore update fails
      setState(() {
        setFieldDate(field, previousValue);
      });
    }
  }

  DateTime? getFieldDate(String field) {
    switch (field) {
      case 'annualTax':
        return _editableCar?.annualTax;
      case 'insurance':
        return _editableCar?.insurance;
      case 'nextServiceInterval':
        return _editableCar?.nextServiceInterval;
      default:
        return null;
    }
  }

  void setFieldDate(String field, DateTime? date) {
    switch (field) {
      case 'annualTax':
        _editableCar = _editableCar?.copyWith(annualTax: date);
        break;
      case 'insurance':
        _editableCar = _editableCar?.copyWith(insurance: date);
        break;
      case 'nextServiceInterval':
        _editableCar = _editableCar?.copyWith(nextServiceInterval: date);
        break;
    }
  }
//this was working
  // Future<void> fetchUpdatedCarDetails() async {
  //   DocumentSnapshot snapshot = await FirebaseFirestore.instance
  //       .collection('cars')
  //       .doc(_editableCar!.id)
  //       .get();

  //   if (snapshot.exists && snapshot.data() != null) {
  //     setState(() {
  //       // Convert the snapshot data to a Map<String, dynamic>
  //       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
  //       // Provide both the data and the document ID to the fromFirestore method
  //       _editableCar = Car.fromFirestore(data, snapshot.id);
  //     });
  //   }
  // }
  Future<void> fetchUpdatedCarDetails() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(_editableCar!.id)
        .get();
    var data = snapshot.data();

    if (data != null) {
      setState(() {
        _editableCar = Car.fromFirestore(data, snapshot.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Car displayCar = updatedCar ??
        widget
            .car; // Use updatedCar if available, otherwise fallback to the initial car details
    final dateFormat = DateFormat('yyyy-MM-dd'); // Define your preferred format
    print("Annual Tax: ${widget.car.annualTax}");
    print("Insurance: ${widget.car.insurance}");
    print("Next Service: ${widget.car.nextServiceInterval}");

    return WillPopScope(
      onWillPop: () async {
        // Indicate that the previous screen might need to refresh or handle the pop action appropriately
        Navigator.pop(context,
            true); // You're passing true back to indicate some action might be needed
        return true; // This allows the navigation to proceed
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(displayCar.make + ' ' + displayCar.model),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildMakeEditField(),
                Text('Model: ${widget.car.model}'),
                Text('VIN: ${widget.car.vin}'),
                Text('License Plate: ${widget.car.licensePlate}'),
                // Conditional display based on whether the date is null or not is no longer needed here
                // as the DateProgressCard itself handles a null date scenario.

                if (widget.car.annualTax != null ||
                    true) // Always true for demonstration; adjust logic as needed
                  DateProgressCard(
                    title: 'Annual Tax',
                    expiryDate: widget.car.annualTax,
                    // onUpdate: (newDate) => updateCarDate('annualTax', newDate),
                    // onDateUpdated: fetchUpdatedCarDetails,
                    onUpdate: (newDate) async {
                      // Assuming you have the car ID and field name to update
                      String carId = _editableCar!.id;
                      await FirebaseFirestore.instance
                          .collection('cars')
                          .doc(carId)
                          .update({
                        'annualTax': Timestamp.fromDate(newDate),
                      });

                      // After updating Firestore, refresh local state
                      fetchUpdatedCarDetails(); // This should fetch the car again and call setState
                    },
                    onDateUpdated: () => {},
                  ),
                if (widget.car.insurance != null ||
                    true) // Always true for demonstration; adjust logic as needed
                  DateProgressCard(
                    title: 'Insurance',
                    expiryDate: widget.car.insurance,
                    onUpdate: (newDate) => updateCarDate('insurance', newDate),
                    onDateUpdated: fetchUpdatedCarDetails,
                  ),
                if (widget.car.nextServiceInterval != null ||
                    true) // Always true for demonstration; adjust logic as needed
                  DateProgressCard(
                    title: 'Next Service Interval',
                    expiryDate: widget.car.nextServiceInterval,
                    onUpdate: (newDate) =>
                        updateCarDate('nextServiceInterval', newDate),
                    onDateUpdated: fetchUpdatedCarDetails,
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.red),
              onPressed: () => deleteCar(context, widget.car.id),
              child: const Text('Delete Car',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}
