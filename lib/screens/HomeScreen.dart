import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/CarDetailsScreen.dart';
import 'package:flutter_application_2/screens/TextScanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_2/models/car.dart';
import 'package:flutter_application_2/screens/loginScreen.dart';
import 'package:flutter_application_2/screens/SettingsScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fcmToken = 'Fetching token...';

  @override
  void initState() {
    super.initState();
    updateFcmToken();
    ;
//new
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('Message received on app launch: ${message.notification?.body}');
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      print(
          'Message received while app is in foreground: ${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
    });

    FirebaseMessaging.instance.getToken().then((token) {
      print("Device token: $token");
      setState(() {
        fcmToken = token ?? "Token not available";
      });
      print(fcmToken);
    });
    //new
  }

  Future<void> updateFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await FirebaseMessaging.instance.getToken();
    if (user != null && token != null) {
      try {
        var userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        var doc = await userDocRef.get();
        if (doc.exists) {
          await userDocRef.update({
            'fcmToken': token,
          });
          print("FCM token updated for user: ${user.uid}");
        } else {
          print(
              "No user document found for ID: ${user.uid}, unable to update FCM token.");
        }
      } catch (e) {
        print("Failed to update FCM token for user: ${user.uid}, error: $e");
      }
    }
  }

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
      //fetch the cars again
    });
  }

  Future<void> performLogout() async {
    await FirebaseAuth.instance.signOut();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshCarsList,
        child: FutureBuilder<List<Car>>(
          future: fetchCars(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            final cars = snapshot.data ?? [];
            if (cars.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 1.3,
                    height: MediaQuery.of(context).size.height,
                    child: const Center(
                        child: Text(
                      'No cars added yet. Please tap the button at the bottom to add a new vehicle!',
                      textAlign: TextAlign.center,
                    )),
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Expanded(
                //   child: ListView.builder(
                //     shrinkWrap: true,
                //     itemCount: cars.length,
                //     itemBuilder: (context, index) {
                //       final car = cars[index];
                //       return ListTile(
                //         title: Text(car.make + ' ' + car.model),
                //         subtitle: Text('License Plate: ${car.licensePlate}'),
                //         onTap: () async {
                //           final result = await Navigator.push(
                //             context,
                //             MaterialPageRoute(
                //                 builder: (context) =>
                //                     CarDetailsScreen(car: car)),
                //           );
                //           if (result == true) {
                //             _refreshCarsList();
                //           }
                //         },
                //       );
                //     },
                //   ),
                // ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      final car = cars[index];
                      return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    CarDetailsScreen(car: car)),
                          );
                          if (result == true) {
                            _refreshCarsList();
                          }
                        },
                        child: Card(
                          elevation: 4,
                          margin:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(car.make,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text(car.model, style: TextStyle(fontSize: 16)),
                                SizedBox(height: 2),
                                Text('License Plate: ${car.licensePlate}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        title: const Text('Fleet Manager'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
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
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('Logout'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await performLogout();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TextScanner()),
          );
        },
        tooltip: 'Open Camera to scan',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
