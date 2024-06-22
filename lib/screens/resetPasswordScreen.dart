// Create a new file for this screen, e.g., reset_password_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_2/widgets/form_container_widget.dart';
import 'package:flutter_application_2/widgets/toast.dart';

class ResetPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Reset Password",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            FormContainerWidget(
              controller: _emailController,
              hintText: "Email",
              isPasswordField: false,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetPassword(context),
              child: Text("Send Reset Link"),
            ),
          ],
        ),
      ),
    );
  }

  void _resetPassword(BuildContext context) async {
    if (_emailController.text.isEmpty) {
      showToast(message: "Email is empty");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      showToast(message: "Reset link sent to your email");
      Navigator.pop(context);
    } catch (e) {
      showToast(message: "Error: ${e.toString()}");
    }
  }
}
