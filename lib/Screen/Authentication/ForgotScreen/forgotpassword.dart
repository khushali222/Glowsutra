import 'package:flutter/material.dart';

class ForgetPasswordScreen extends StatelessWidget {
  final phoneController = TextEditingController();

  void _sendOtp() {
    print("Sending OTP to: ${phoneController.text}");

    // TODO: Connect with Firebase Phone Auth
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Mobile Number'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendOtp,
              child: Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}