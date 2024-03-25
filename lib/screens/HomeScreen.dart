import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/CarDetailsScreen.dart';
import 'package:flutter_application_2/screens/TextScanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/screens/loginScreen.dart';

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
  Future<void> performLogout() async {
    // Assuming you're using Firebase Auth for example
    await FirebaseAuth.instance.signOut();

    // Navigate to the login screen (replace the current route)
    // Ensure this is done in a way that doesn't conflict with drawer navigation
    // This might need to be scheduled post frame to ensure the drawer pop has completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

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
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(child: Text('No cars added yet.')),
                ),
              );
            }

            return ListView.builder(
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return ListTile(
                  title: Text(car.make + ' ' + car.model),
                  subtitle: Text('License Plate: ${car.licensePlate}'),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CarDetailsScreen(car: car)),
                    );
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
      appBar: AppBar(
        title: Text('Fleet Manager'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                // Close the drawer first
                Navigator.pop(
                    context); // Make sure to close the drawer before showing the dialog
                // Show a confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context)
                            .pop(false), // User pressed Cancel, don't logout
                      ),
                      TextButton(
                        child: Text('Logout'),
                        onPressed: () => Navigator.of(context)
                            .pop(true), // User pressed Logout, do logout
                      ),
                    ],
                  ),
                );

                // Check the user's decision
                if (shouldLogout == true) {
                  await performLogout(); // Perform logout operation
                }
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TextScanner()),
          );
        },
        child: Icon(Icons.camera_alt),
        tooltip: 'Open Camera to scan',
      ),
    );
  }
}
