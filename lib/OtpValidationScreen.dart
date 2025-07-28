import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpValidation extends StatefulWidget {
  @override
  _OtpValidationState createState() => _OtpValidationState();
}

class _OtpValidationState extends State<OtpValidation> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(fontSize: 20, color: Colors.black),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 50, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Password reset',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'We sent a code to amelie@untitledui.com',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Pinput(
              length: 4,
              controller: _pinController,
              focusNode: _pinFocusNode,
              defaultPinTheme: defaultPinTheme,
              separatorBuilder: (index) => SizedBox(width: 10),
              onCompleted: (pin) {
                // Handle OTP completion if needed
                print('OTP entered: $pin');
              },
              onChanged: (value) {
                if (value.length == 4) {
                  _pinFocusNode.unfocus();
                }
              },
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Continue', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {},
              child: Text('Didn\'t receive the email? Click to resend'),
            ),
          ],
        ),
      ),
    );
  }
}