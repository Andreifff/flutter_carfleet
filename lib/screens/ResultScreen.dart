import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/screens/HomeScreen.dart'; // Ensure this import path is correct

class ResultScreen extends StatefulWidget {
  final String text;
  final String? licensePlate;
  final String? vin;

  const ResultScreen(
      {Key? key, required this.text, this.licensePlate, this.vin})
      : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _carMakeController;
  late TextEditingController _carModelController;

  @override
  void initState() {
    super.initState();
    _licensePlateController = TextEditingController(text: widget.licensePlate);
    _vinController = TextEditingController(text: widget.vin);
    _carMakeController = TextEditingController();
    _carModelController = TextEditingController();
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vinController.dispose();
    _carMakeController.dispose();
    _carModelController.dispose();
    super.dispose();
  }

  Future<void> addCarToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Car car = Car(
        make: _carMakeController.text, // Use the value from the controller
        model: _carModelController.text, // Use the value from the controller
        vin: _vinController.text, // Use the value from the controller
        licensePlate: _licensePlateController.text,
        id: '', // Use the value from the controller
        // Add additional fields as required
      );

      await FirebaseFirestore.instance.collection('cars').add({
        ...car.toJson(),
        'userId': user.uid, // Associate car with the current user
      }).then((docRef) {
        // Handle success, perhaps show a confirmation message
        print("Car added successfully");

        // Navigate back to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }).catchError((error) {
        // Handle errors, perhaps show an error message
        print("Error adding car: $error");
      });
    } else {
      // Handle the case where there is no logged-in user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _licensePlateController,
                decoration: InputDecoration(labelText: 'License Plate'),
              ),
              TextFormField(
                controller: _vinController,
                decoration: InputDecoration(labelText: 'VIN'),
              ),
              TextFormField(
                controller: _carMakeController,
                decoration: InputDecoration(labelText: 'Car Make'),
              ),
              TextFormField(
                controller: _carModelController,
                decoration: InputDecoration(labelText: 'Car Model'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity,
                        50), // make the button full-width and 50px high
                  ),
                  onPressed:
                      addCarToFirebase, // Adjusted to call the method correctly
                  child: const Text('Add Car'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
