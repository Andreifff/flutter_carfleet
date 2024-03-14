import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/CarDetailsScreen.dart';
import 'package:flutter_application_2/screens/TextScanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/car.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Car>> fetchCars() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('userId', isEqualTo: user.uid)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return Car(
          id: doc.id,
          make: data['make'],
          model: data['model'],
          vin: data['vin'],
          licensePlate: data['licensePlate'],
          annualTax: data['annualTax'] != null
              ? (data['annualTax'] as Timestamp).toDate()
              : null,
          insurance: data['insurance'] != null
              ? (data['insurance'] as Timestamp).toDate()
              : null,
          nextServiceInterval: data['nextServiceInterval'] != null
              ? (data['nextServiceInterval'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } else {
      return [];
    }
  }

  Future<void> _refreshCarsList() async {
    setState(() {
      // This triggers the FutureBuilder to reload and fetch the cars again
    });
  }
// Future<void> navigateAndCheckIfRefreshNeeded(BuildContext context) async {
//   final result = await Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => CarDetailsScreen(car: car), // Make sure to pass the correct car or necessary data
//     ),
//   );

//   if (result == true) {
//     // Refresh your data here
//     _refreshCarsList();
//   }
// }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Center(
  //       child: ElevatedButton(
  //         onPressed: () {
  //           Navigator.push(context,
  //               MaterialPageRoute(builder: (context) => TextScanner()));
  //         },
  //         child: const Text('Open Camera to scan'),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        // The onRefresh function that's called when the user pulls down to refresh
        onRefresh: _refreshCarsList,
        child: FutureBuilder<List<Car>>(
          future: fetchCars(), // This fetches the cars, same as before
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Using a SingleChildScrollView with a sized box to ensure the RefreshIndicator always works
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final cars = snapshot.data ?? [];
            if (cars.isEmpty) {
              // For an empty list, also using a SingleChildScrollView to ensure pull-to-refresh works
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No cars added yet.'),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TextScanner()));
                          },
                          child: const Text('Open Camera to scan'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity,
                                50), // Full-width button with fixed height
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // If there are cars, display them in a list view that can be refreshed
            return ListView.builder(
              itemCount:
                  cars.length + 1, // Adding +1 for the button at the bottom
              itemBuilder: (context, index) {
                if (index == cars.length) {
                  // The last item is the button
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TextScanner()));
                      },
                      child: const Text('Open Camera to scan'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity,
                            50), // Full-width button with fixed height
                      ),
                    ),
                  );
                }
                final car = cars[index];
                return ListTile(
                  title: Text(car.make + ' ' + car.model),
                  subtitle: Text('License Plate: ${car.licensePlate}'),
                  // onTap: () async {
                  //   final result = await Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //         builder: (context) => CarDetailsScreen(car: car)),
                  //   );

                  //   // If the CarDetailsScreen indicates that a change has been made, refresh the list.
                  //   if (result == true) {
                  //     _refreshCarsList();
                  //   }
                  // },
                  onTap: () async {
                    // Use Navigator.push and await the result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CarDetailsScreen(car: cars[index]),
                      ),
                    );

                    // Check if the result is true, indicating that a refresh is needed
                    if (result == true) {
                      _refreshCarsList();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
