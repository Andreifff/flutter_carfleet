import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/car.dart'; // Update this import path as necessary
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/spending.dart';
import 'package:flutter_application_2/widgets/dateProgressCard.dart';
import 'package:flutter_application_2/widgets/spendingsCard.dart';
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

  List<Spending> spendings = [];
  final List<String> categories = [
    'Fuel',
    'Maintenance',
    'Other',
    'Custom'
  ]; // Add 'Custom' option
  String? selectedCategory;
  bool showCustomCategoryField =
      false; // Flag to show/hide the custom category TextField
  TextEditingController customCategoryController =
      TextEditingController(); // Controller for the custom category TextField

  @override
  void initState() {
    super.initState();
    updatedCar = widget.car; // Initial car details
    _editableCar = widget.car;
    selectedCategory = categories.first;
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

  void _showEditMakeDialog2() async {
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

  Widget _buildMakeEditField2() {
    return Row(
      children: [
        Expanded(
          child: Text(
              'Make: ${_editableCar?.make ?? 'N/A'}'), // Displays the car make
        ),
        IconButton(
          icon: Icon(Icons.edit), // The edit icon
          onPressed: _showEditMakeDialog2, // Calls the dialog when tapped
        ),
      ],
    );
  }

//format licence plate method
  String formatLicensePlate(String input) {
    // Trim and convert to uppercase
    String formattedInput = input.trim().toUpperCase();

    // Define the pattern for the license plate
    RegExp regExp = RegExp(r'^([A-Z]{1,2})-?(\d{2,3})-?([A-Z]{3})$');

    // Check if the input matches the pattern
    if (regExp.hasMatch(formattedInput)) {
      final matches = regExp.firstMatch(formattedInput);

      // Rebuild the license plate with correct formatting
      String part1 = matches?.group(1) ?? '';
      String part2 = matches?.group(2) ?? '';
      String part3 = matches?.group(3) ?? '';

      return '$part1-$part2-$part3';
    }

    // Return the input as is if it doesn't match the pattern
    // Consider handling this case, e.g., showing an error to the user
    return input;
  }

  //new version for the ones above
//FOR EDITING THE FIELDS IN THE CARDETAILSSCRENN
  Future<void> _showEditDialog(
      String field, String currentValue, String hintText, String title) async {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    final String? newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );

    // Check for non-null newValue and difference from currentValue
    if (newValue != null && newValue.trim() != currentValue) {
      // Apply formatting if the field being edited is the license plate
      String finalValue = field == "licensePlate"
          ? formatLicensePlate(newValue.trim())
          : newValue.trim();

      await updateCarDetailsInFirestore(field, finalValue);
      _refreshEditableCar();
    }
  }

  String _formatLicensePlate(String input) {
    input = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (input.startsWith('B') && input.length > 3) {
      // Format as B-100-XYZ or similar
      return '${input.substring(0, 1)}-${input.substring(1, 4)}-${input.substring(4)}'
          .trimRight();
    } else {
      // Format as XX-00-XYZ or similar
      return '${input.substring(0, 2)}-${input.substring(2, 4)}-${input.substring(4)}'
          .trimRight();
    }

    // Return input as is if it doesn't meet any of the above criteria
    return input;
  }

  bool _isValidLicensePlate(String input) {
    // Adjust the regex for validation
    final regexB = RegExp(r'^B-\d{3}-[A-Z]{3}$');
    final regexOther = RegExp(r'^[A-Z]{2}-\d{2}-[A-Z]{3}$');
    return regexB.hasMatch(input) || regexOther.hasMatch(input);
  }

  Widget _buildEditableField(String field, String currentValue, String title) {
    return Row(
      children: [
        Expanded(
          child:
              Text('$title: ${currentValue.isNotEmpty ? currentValue : 'N/A'}'),
        ),
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _showEditDialog(
              field, currentValue, "Enter car's new $title", title),
        ),
      ],
    );
  }

  Future<void> deleteCar2(BuildContext context, String carId) async {
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

  Future<void> deleteCar(BuildContext context, String carId) async {
    // Show a confirmation dialog before deleting
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Car'),
          content: Text('Are you sure you want to delete this car?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext)
                  .pop(false), // Dismisses the dialog returning 'false'
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () => Navigator.of(dialogContext)
                  .pop(true), // Dismisses the dialog returning 'true'
            ),
          ],
        );
      },
    );

    // Proceed with deletion if confirmed
    if (confirmDelete == true && carId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
        Navigator.pop(context,
            true); // Navigate back after successful deletion, potentially passing 'true' to indicate that deletion occurred
      } catch (e) {
        // Handle deletion error
        print("Error deleting car: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to delete car.")));
      }
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

//THIS WAS WORKING TOO
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

//   void updateCarDate2(String field, DateTime date) async {
//   // Optimistically update UI
//   setState(() {
//     _editableCar = _editableCar.copyWith(field: date); // Adjust copyWith to handle the field dynamically or use specific methods
//   });

//   try {
//     await FirebaseFirestore.instance.collection('cars').doc(_editableCar?.id).update({field: date});
//     // Firestore update succeeded, now fetch updated details or leave optimistic update
//   } catch (e) {
//     // Firestore update failed, revert optimistic update or handle error
//   }
// }

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

  Future<void> _showAddSpendingDialog(BuildContext context) async {
    TextEditingController amountController = TextEditingController();
    TextEditingController odometerController = TextEditingController();
    TextEditingController currencyController = TextEditingController();
    // Removed categoryController as we're going to use local state for category selection

    String selectedCategory = 'Fuel'; // Default to first category
    TextEditingController customCategoryController = TextEditingController();
    bool showCustomCategoryField = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Add Spending"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value ?? categories.first;
                          showCustomCategoryField = value == 'Custom';
                        });
                      },
                    ),
                    if (showCustomCategoryField) // Conditionally show the TextField
                      TextField(
                        controller: customCategoryController,
                        decoration:
                            InputDecoration(hintText: "Custom Category"),
                      ),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(hintText: "Amount"),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: odometerController,
                      decoration: InputDecoration(hintText: "Odometer"),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: currencyController,
                      decoration:
                          InputDecoration(hintText: "Currency (e.g., USD)"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Add"),
                  onPressed: () {
                    String finalCategory = showCustomCategoryField
                        ? customCategoryController.text
                        : selectedCategory;
                    if (amountController.text.isNotEmpty &&
                        odometerController.text.isNotEmpty &&
                        currencyController.text.isNotEmpty) {
                      _addSpendingToFirestore(
                        finalCategory,
                        double.parse(amountController.text),
                        int.parse(odometerController.text),
                        currencyController.text,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addSpendingToFirestore(
      String category, double amount, int odometer, String currency) async {
    final spending = Spending(
      category: category,
      amount: amount,
      odometer: odometer,
      currency: currency,
      date: DateTime.now(),
    );

    // Assuming you have a carId variable that contains the ID of the current car
    String carId = _editableCar!.id;

    // Add the spending to Firestore under the current car document
    // This example assumes you have a subcollection 'spendings' under each car document
    await FirebaseFirestore.instance
        .collection('cars')
        .doc(carId)
        .collection('spendings')
        .add(spending.toJson());

    // Optionally refresh your UI or state to reflect the new spending
    _refreshEditableCar(); // This might need adjustments based on how your app is structured
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
                //_buildMakeEditField(),
                //new version
                _buildEditableField('make', _editableCar?.make ?? '', 'Make'),
                _buildEditableField(
                    'model', _editableCar?.model ?? '', 'Model'),
                _buildEditableField('vin', _editableCar?.vin ?? '', 'VIN'),
                _buildEditableField('licensePlate',
                    _editableCar?.licensePlate ?? '', 'License Plate'),
                // Text('Model: ${widget.car.model}'),
                // Text('VIN: ${widget.car.vin}'),
                // Text('License Plate: ${widget.car.licensePlate}'),

                // Conditional display based on whether the date is null or not is no longer needed here
                // as the DateProgressCard itself handles a null date scenario.

                if (widget.car.annualTax != null ||
                    true) // Always true for demonstration; adjust logic as needed
                  DateProgressCard(
                    title: 'Annual Tax',
                    initialExpiryDate: widget.car.annualTax,
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
                  ),
                if (widget.car.insurance != null ||
                    true) // Always true for demonstration; adjust logic as needed
                  DateProgressCard(
                    title: 'Insurance',
                    initialExpiryDate: widget.car.insurance,
                    onUpdate: (newDate) async {
                      await updateCarDate('insurance', newDate);
                      fetchUpdatedCarDetails();
                    },
                  ),
                if (widget.car.nextServiceInterval != null || true)
                  DateProgressCard(
                    title: 'Next Service Interval',
                    initialExpiryDate: widget.car.nextServiceInterval,
                    onUpdate: (newDate) async {
                      await updateCarDate('nextServiceInterval', newDate);
                      fetchUpdatedCarDetails();
                    },
                  ),
                SpendingsCard(
                  car: _editableCar!,
                  onAddSpending: () => _showAddSpendingDialog(context),
                  onSpendingAdded: _refreshEditableCar,
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
