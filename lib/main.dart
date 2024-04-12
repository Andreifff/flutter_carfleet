import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/SettingsScreen.dart';
import 'package:flutter_application_2/models/theme_provider.dart'; // Import your theme provider
import 'package:provider/provider.dart';
import 'screens/loginScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission
  NotificationSettings settings = await messaging.requestPermission();
  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: MyApp(),
  ));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Fleet Manager',
            theme: themeProvider.isDarkMode
                ? ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark().copyWith(
                      primary: Color.fromARGB(255, 0, 140, 255),
                    ),
                  )
                : ThemeData.light().copyWith(
                    colorScheme: ColorScheme.light().copyWith(
                      primary: Color.fromARGB(255, 0, 140, 255),
                    ),
                  ),
            initialRoute: '/',
            home: const LoginPage(),
          );
        },
      ),
    );
  }
}
