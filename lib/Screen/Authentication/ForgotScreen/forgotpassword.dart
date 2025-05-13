import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;
  late String verificationId;

  bool _isOtpSent = false;
  bool _isLoading = false;

  // Send OTP to the user's mobile number
  void _sendOtp() async {
    setState(() {
      _isLoading = true;
    });

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${phoneController.text.trim()}', // Add country code (e.g., +91 for India)
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verification is complete
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: 'Failed to send OTP: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          this.verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: 'OTP sent to ${phoneController.text}');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto-retrieval timeout (not used in this case)
      },
    );
  }

  // Verify OTP and reset password
  void _verifyOtpAndResetPassword() async {
    setState(() {
      _isLoading = true;
    });

    // Get the OTP entered by the user
    String otp = otpController.text.trim();

    try {
      // Create a PhoneAuthCredential with the verificationId and OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with the credential
      await _auth.signInWithCredential(credential);

      // If OTP is correct, proceed to change the password
      await _auth.currentUser?.updatePassword(newPasswordController.text.trim());

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(msg: 'Password reset successful!');
      // Optionally navigate the user to the login screen after password reset.
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Failed to reset password: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mobile number input
            if (!_isOtpSent) ...[
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendOtp,
                child: _isLoading ? CircularProgressIndicator() : Text('Send OTP'),
              ),
            ] else ...[
              // OTP input
              TextField(
                controller: otpController,
                decoration: InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              // New password input
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOtpAndResetPassword,
                child: _isLoading ? CircularProgressIndicator() : Text('Reset Password'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
