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

  // Error messages
  String? phoneError;
  String? otpError;
  String? passwordError;

  void _sendOtp() async {
    setState(() {
      phoneError = null;
    });

    if (phoneController.text.trim().isEmpty) {
      setState(() => phoneError = 'Mobile number is required');
      return;
    }

    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${phoneController.text.trim()}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
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
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _verifyOtpAndResetPassword() async {
    setState(() {
      otpError = null;
      passwordError = null;
    });

    if (otpController.text.trim().isEmpty) {
      setState(() => otpError = 'OTP is required');
      return;
    }

    if (newPasswordController.text.trim().isEmpty) {
      setState(() => passwordError = 'Password is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      await _auth.currentUser?.updatePassword(newPasswordController.text.trim());

      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Password reset successful!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'Failed to reset password: ${e.message}');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isOtpSent) ...[
              _buildTextField(
                controller: phoneController,
                label: 'Mobile Number',
                keyboardType: TextInputType.phone,
                errorText: phoneError,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Send OTP', style: TextStyle(fontSize: 16)),
              ),
            ] else ...[
              _buildTextField(
                controller: otpController,
                label: 'Enter OTP',
                keyboardType: TextInputType.number,
                errorText: otpError,
              ),
              SizedBox(height: 20),
              _buildTextField(
                controller: newPasswordController,
                label: 'New Password',
                obscureText: true,
                errorText: passwordError,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndResetPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Reset Password', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
