import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/car_document.dart';
import 'package:flutter_application_2/models/spending.dart';
import 'package:flutter_application_2/screens/StatisticsScreen.dart';
import 'package:flutter_application_2/services/firebase_api.dart';
import 'package:flutter_application_2/services/utilities.dart';
import 'package:flutter_application_2/widgets/dateProgressCard.dart';
import 'package:flutter_application_2/widgets/spendingsCard.dart';
import 'package:flutter_application_2/widgets/documentCard.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late TextEditingController currencyController;
  String selectedCurrency = 'EUR';

  List<Spending> spendings = [];
  final List<String> categories = ['Fuel', 'Maintenance', 'Other', 'Custom'];
  String? selectedCategory;
  bool showCustomCategoryField = false;
  TextEditingController customCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    updatedCar = widget.car;
    _editableCar = widget.car;
    selectedCategory = categories.first;
    _loadCurrencyPreference();
  }

  Future<void> updateCarDetailsInFirestore(String field, dynamic value) async {
    try {
      var documentReference =
          FirebaseFirestore.instance.collection('cars').doc(_editableCar!.id);
      print("Attempting to update document with ID: ${_editableCar!.id}");

      var doc = await documentReference.get();

      if (doc.exists) {
        await documentReference.update({field: value});
        print("Document updated");
        _refreshEditableCar();
      } else {
        print("Document with ID ${_editableCar!.id} does not exist.");
      }
    } catch (e) {
      print("Error updating document: $e");
    }
  }

  Future<void> _refreshEditableCar() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(_editableCar!.id)
        .get();
    Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
    if (data != null) {
      setState(() {
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
          icon: Icon(Icons.edit),
          onPressed: _showEditMakeDialog2,
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
    return input;
  }

//FOR EDITING THE FIELDS IN THE CARDETAILSSCREEN
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

    if (newValue != null && newValue.trim() != currentValue) {
      String finalValue = field == "licensePlate"
          ? formatLicensePlate(newValue.trim())
          : newValue.trim();

      await updateCarDetailsInFirestore(field, finalValue);
      _refreshEditableCar();
    }
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
        Navigator.pop(context, true);
      } catch (e) {
        print("Error deleting car: $e");
      }
    } else {
      print("Car ID is empty, cannot delete car.");
    }
  }

  Future<void> deleteCar(BuildContext context, String carId) async {
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

    if (confirmDelete == true && carId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('cars').doc(carId).delete();
        Navigator.pop(context, true);
      } catch (e) {
        // Handle deletion error
        print("Error deleting car: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to delete car.")));
      }
    }
  }

  //THIS WAS WORKING TOO
  Future<void> updateCarDate(String field, DateTime date) async {
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
      print("Date updated successfully in Firestore.");
    } catch (e) {
      print("Error updating date in Firestore: $e");
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

  Future<void> uploadDocumentPicker(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      if (file.path == null) {
        print("File path is null");
        return;
      }
      File documentFile = File(file.path!);
      String fileName = file.name;
      try {
        String uniqueFileName =
            "${DateTime.now().millisecondsSinceEpoch}_$fileName";
        Reference storageReference =
            FirebaseStorage.instance.ref().child("documents/$uniqueFileName");

        await storageReference.putFile(documentFile);

        String fileUrl = await storageReference.getDownloadURL();

        await FirebaseFirestore.instance.collection("carDocuments").add({
          'name': fileName, // Original file name
          'url': fileUrl, // URL to access the file
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File uploaded successfully")));
        refreshDocuments();
      } catch (e) {
        print("Error uploading file: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to upload file")));
      }
    } else {
      print("No file selected");
    }
  }

  Future<void> uploadDocumentPicker2(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String documentName =
          '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      String filePath = 'cars/${widget.car.id}/documents/$documentName';

      try {
        // Getting the current user's UID
        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        Reference storageReference =
            FirebaseStorage.instance.ref().child(filePath);
        SettableMetadata metadata =
            SettableMetadata(customMetadata: {'userId': userId});

        await storageReference.putFile(
            file, metadata); // Include metadata in the upload
        String fileUrl = await storageReference.getDownloadURL();

        // Save document details to Firestore under the car's documents collection
        await FirebaseFirestore.instance
            .collection('cars')
            .doc(widget.car.id)
            .collection('documents')
            .doc(documentName)
            .set({
          'name': fileName,
          'url': fileUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
          'uploaderId':
              userId, // Save the uploader's ID to Firestore for additional verification if needed
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Document uploaded successfully")));
        _refreshEditableCar();
      } catch (e) {
        print("Error uploading document: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error uploading document")));
      }
    } else {
      print("No file selected");
    }
  }

  Future<void> uploadDocument(File document, String carId) async {
    try {
      print(
          'Is user authenticated? ${FirebaseAuth.instance.currentUser != null}');

      print("Uploading document for car ID: $carId");

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('cars')
          .doc(carId)
          .collection('documents')
          .doc();

      String documentName = docRef.id;
      String filePath = 'cars/$carId/documents/$documentName';

      print("Generated file path: $filePath");

      Reference storageReference =
          FirebaseStorage.instance.ref().child(filePath);
      await storageReference.putFile(document);

      String documentUrl = await storageReference.getDownloadURL();
      print(documentUrl);

      await docRef.set({
        'name': documentName,
        'url': documentUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _refreshEditableCar();
    } catch (e, stackTrace) {
      if (e is FirebaseException) {
        print('FirebaseException Code: ${e.code}');
        print('FirebaseException Message: ${e.message}');
      } else {
        print('Error uploading document: $e');
      }
      print('Stack trace: $stackTrace');
    }
  }

  // Future<void> _showAddSpendingDialog(BuildContext context) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String defaultCurrency = prefs.getString('selectedCurrency') ?? 'EUR';
  //   TextEditingController amountController = TextEditingController();
  //   TextEditingController odometerController = TextEditingController();
  //   //TextEditingController currencyController = TextEditingController();
  //   String selectedCategory = 'Fuel'; // Default to first category
  //   TextEditingController customCategoryController = TextEditingController();
  //   bool showCustomCategoryField = false;
  //   String selectedCurrency = defaultCurrency;

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return AlertDialog(
  //             title: Text("Add Spending"),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   DropdownButtonFormField<String>(
  //                     value: selectedCategory,
  //                     items: categories
  //                         .map<DropdownMenuItem<String>>((String value) {
  //                       return DropdownMenuItem<String>(
  //                         value: value,
  //                         child: Text(value),
  //                       );
  //                     }).toList(),
  //                     onChanged: (value) {
  //                       setState(() {
  //                         selectedCategory = value ?? categories.first;
  //                         showCustomCategoryField = value == 'Custom';
  //                       });
  //                     },
  //                   ),
  //                   if (showCustomCategoryField) // Conditionally show the TextField
  //                     TextField(
  //                       controller: customCategoryController,
  //                       decoration:
  //                           InputDecoration(hintText: "Custom Category"),
  //                     ),
  //                   TextField(
  //                     controller: amountController,
  //                     decoration: InputDecoration(hintText: "Amount"),
  //                     keyboardType:
  //                         TextInputType.numberWithOptions(decimal: true),
  //                   ),
  //                   TextField(
  //                     controller: odometerController,
  //                     decoration: InputDecoration(hintText: "Odometer"),
  //                     keyboardType: TextInputType.number,
  //                   ),
  //                   // TextField(
  //                   //   controller: currencyController,
  //                   //   decoration:
  //                   //       InputDecoration(hintText: "Currency (e.g., USD)"),
  //                   // ),
  //                   DropdownButton<String>(
  //                     value:
  //                         defaultCurrency, // This should be the state variable in your dialog
  //                     onChanged: (String? newValue) {
  //                       setState(() {
  //                         selectedCurrency = newValue!;
  //                       });
  //                     },
  //                     items: CurrencyUtil.currencies
  //                         .map<DropdownMenuItem<String>>((String value) {
  //                       return DropdownMenuItem<String>(
  //                         value: value,
  //                         child: Text(value),
  //                       );
  //                     }).toList(),
  //                   )
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 child: Text("Cancel"),
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //               TextButton(
  //                 child: Text("Add"),
  //                 onPressed: () {
  //                   String finalCategory = showCustomCategoryField
  //                       ? customCategoryController.text
  //                       : selectedCategory;
  //                   if (amountController.text.isNotEmpty &&
  //                       odometerController.text.isNotEmpty &&
  //                       currencyController.text.isNotEmpty) {
  //                     _addSpendingToFirestore(
  //                       finalCategory,
  //                       double.parse(amountController.text),
  //                       int.parse(odometerController.text),
  //                       currencyController.text,
  //                     );
  //                     Navigator.of(context).pop();
  //                   }
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
  //This one above is working

  Future<void> _showAddSpendingDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String defaultCurrency = prefs.getString('selectedCurrency') ?? 'EUR';
    TextEditingController amountController = TextEditingController();
    TextEditingController odometerController = TextEditingController();
    String selectedCategory = 'Fuel'; // Default to first category
    TextEditingController customCategoryController = TextEditingController();
    bool showCustomCategoryField = false;
    String currencyInDialog = defaultCurrency;

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
                    // TextField(
                    //   controller: currencyController,
                    //   decoration:
                    //       InputDecoration(hintText: "Currency (e.g., USD)"),
                    // ),
                    DropdownButton<String>(
                      value:
                          currencyInDialog, // Use the dialog's currency state
                      onChanged: (String? newValue) {
                        setState(() {
                          currencyInDialog =
                              newValue!; // Update the dialog's currency state
                        });
                      },
                      items: CurrencyUtil.currencies
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                // Actions...
                TextButton(
                  child: Text("Add"),
                  onPressed: () {
                    String finalCategory = showCustomCategoryField
                        ? customCategoryController.text
                        : selectedCategory;
                    if (amountController.text.isNotEmpty &&
                        odometerController.text.isNotEmpty) {
                      _addSpendingToFirestore(
                        finalCategory,
                        double.parse(amountController.text),
                        int.parse(odometerController.text),
                        currencyInDialog, // Use the selected currency from dialog
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

  // Future<void> _showEditSpendingDialog(
  //     BuildContext context, Spending spending, String spendingId) async {
  //   // Controllers pre-filled with the spending data
  //   TextEditingController amountController =
  //       TextEditingController(text: spending.amount.toString());
  //   TextEditingController odometerController =
  //       TextEditingController(text: spending.odometer.toString());
  //   TextEditingController currencyController =
  //       TextEditingController(text: spending.currency);

  //   String selectedCategory = spending.category; // Pre-fill the category
  //   TextEditingController customCategoryController = TextEditingController();
  //   bool showCustomCategoryField = selectedCategory == 'Custom';

  //   // In case 'Custom' category was selected, pre-fill the custom category field
  //   if (showCustomCategoryField) {
  //     customCategoryController.text = spending.category;
  //   }

  //   showDialog(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return AlertDialog(
  //             title: Text("Edit Spending"),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   DropdownButtonFormField<String>(
  //                     value: selectedCategory,
  //                     items: categories
  //                         .map<DropdownMenuItem<String>>((String value) {
  //                       return DropdownMenuItem<String>(
  //                         value: value,
  //                         child: Text(value),
  //                       );
  //                     }).toList(),
  //                     onChanged: (value) {
  //                       setState(() {
  //                         selectedCategory = value ?? categories.first;
  //                         showCustomCategoryField = value == 'Custom';
  //                       });
  //                     },
  //                   ),
  //                   if (showCustomCategoryField) // Conditionally show the TextField
  //                     TextField(
  //                       controller: customCategoryController,
  //                       decoration:
  //                           InputDecoration(hintText: "Custom Category"),
  //                     ),
  //                   TextField(
  //                     controller: amountController,
  //                     decoration: InputDecoration(hintText: "Amount"),
  //                     keyboardType:
  //                         TextInputType.numberWithOptions(decimal: true),
  //                   ),
  //                   TextField(
  //                     controller: odometerController,
  //                     decoration: InputDecoration(hintText: "Odometer"),
  //                     keyboardType: TextInputType.number,
  //                   ),
  //                   TextField(
  //                     controller: currencyController,
  //                     decoration:
  //                         InputDecoration(hintText: "Currency (e.g., USD)"),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 child: Text("Cancel"),
  //                 onPressed: () => Navigator.of(dialogContext).pop(),
  //               ),
  //               TextButton(
  //                 child: Text("Save"),
  //                 onPressed: () {
  //                   String finalCategory = showCustomCategoryField
  //                       ? customCategoryController.text
  //                       : selectedCategory;
  //                   // Implement the logic for updating the spending in Firestore
  //                   _updateSpendingInFirestore(
  //                       spendingId,
  //                       finalCategory,
  //                       double.parse(amountController.text),
  //                       int.parse(odometerController.text),
  //                       currencyController.text);
  //                   Navigator.of(dialogContext).pop();
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void refreshDocuments() {
    setState(() {});
  }

  Future<void> _updateSpending(
      String spendingId, Spending existingSpending) async {
    TextEditingController categoryController =
        TextEditingController(text: existingSpending.category);
    TextEditingController amountController =
        TextEditingController(text: existingSpending.amount.toString());
    TextEditingController odometerController =
        TextEditingController(text: existingSpending.odometer.toString());
    TextEditingController currencyController =
        TextEditingController(text: existingSpending.currency);

    final selectedDate = existingSpending.date;

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update Spending"),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(hintText: "Category"),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: "Amount"),
                ),
                TextField(
                  controller: odometerController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: "Odometer"),
                ),
                TextField(
                  controller: currencyController,
                  decoration: InputDecoration(hintText: "Currency"),
                ),
                // Add more fields as necessary
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Update Firestore document
                FirebaseFirestore.instance
                    .collection('cars')
                    .doc(_editableCar!.id)
                    .collection('spendings')
                    .doc(spendingId)
                    .update({
                  'category': categoryController.text,
                  'amount': double.tryParse(amountController.text) ??
                      existingSpending.amount,
                  'odometer': int.tryParse(odometerController.text) ??
                      existingSpending.odometer,
                  'currency': currencyController.text,
                  // Add additional fields here
                });

                Navigator.of(context).pop(true);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );

    if (updated == true) {
      // Optionally refresh your UI here
      _refreshEditableCar();
    }
  }

  Future<void> _deleteSpending(String spendingId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Spending"),
          content: Text("Are you sure you want to delete this spending?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      FirebaseFirestore.instance
          .collection('cars')
          .doc(_editableCar!.id)
          .collection('spendings')
          .doc(spendingId)
          .delete();

      _refreshEditableCar();
    }
  }

  Future<void> _addSpendingToFirestore(
      String category, double amount, int odometer, String currency) async {
    final spending = Spending(
      id: '',
      category: category,
      amount: amount,
      odometer: odometer,
      currency: currency,
      date: DateTime.now(),
    );

    String carId = _editableCar!.id;
    await FirebaseFirestore.instance
        .collection('cars')
        .doc(carId)
        .collection('spendings')
        .add(spending.toJson());
    _refreshEditableCar();
  }

  void refreshDocumentsList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Car displayCar = updatedCar ?? widget.car;
    final dateFormat = DateFormat('dd-MM-yyyy');
    print("Annual Tax: ${widget.car.annualTax}");
    print("Insurance: ${widget.car.insurance}");
    print("Next Service: ${widget.car.nextServiceInterval}");

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(displayCar.make + ' ' + displayCar.model),
          actions: [
            IconButton(
              icon: Icon(Icons.pie_chart),
              onPressed: () {
                if (_editableCar != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StatisticsScreen(car: _editableCar!),
                    ),
                  );
                } else {
                  // Handle the case where _editableCar is null, if necessary
                  print("Car is null, cannot navigate to StatisticsScreen");
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildEditableField('make', _editableCar?.make ?? '', 'Make'),
                _buildEditableField(
                    'model', _editableCar?.model ?? '', 'Model'),
                _buildEditableField('vin', _editableCar?.vin ?? '', 'VIN'),
                _buildEditableField('licensePlate',
                    _editableCar?.licensePlate ?? '', 'License Plate'),
                if (widget.car.annualTax != null || true)
                  DateProgressCard(
                    title: 'Annual Tax',
                    initialExpiryDate: widget.car.annualTax,
                    onUpdate: (newDate) async {
                      String carId = _editableCar!.id;
                      await FirebaseFirestore.instance
                          .collection('cars')
                          .doc(carId)
                          .update({
                        'annualTax': Timestamp.fromDate(newDate),
                      });

                      fetchUpdatedCarDetails(); // This should fetch the car again and call setState
                    },
                  ),
                if (widget.car.insurance != null || true)
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
                  onUpdateSpending: _updateSpending,
                  onDeleteSpending: _deleteSpending,
                  selectedCurrency: selectedCurrency,
                ),
                DocumentsCard(
                  car: widget.car,
                  onDocumentAdded: () => uploadDocumentPicker2(context),
                  onRefreshRequested: refreshDocuments,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.red),
              onPressed: () => deleteCar(context, widget.car.id),
              child: Text('Delete Car', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();

    String? savedCurrency = prefs.getString('selectedCurrency') ?? "USD";
    setState(() {
      currencyController = TextEditingController(text: savedCurrency);
      selectedCurrency = savedCurrency;
    });
  }
}
