import 'package:coincraze/AuthManager.dart';

import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/UpdatePassword.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pinput/pinput.dart';

class VerifyOtp extends StatefulWidget {
  const VerifyOtp({super.key});

  @override
  State<VerifyOtp> createState() => _VerifyOtpState();
}

class _VerifyOtpState extends State<VerifyOtp>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final Email = AuthManager().email ?? 'Empty';

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(2, 0.4), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.ease),
        );
    _animationController.forward();
    _initAuthManager(); // Initialize AuthManager
  }

  Future<void> _initAuthManager() async {
    await AuthManager().init(); // Initialize Hive and load saved details
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: TextStyle(fontSize: 20, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 3, 4, 4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              // Curved Container with Background Image
              ClipPath(
                clipper: CurvedClipper(),
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/e.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.7),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Center(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Image.asset(
                        'assets/images/whtLogo.png',
                        width: 260,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Text(
                          "Password Reset",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 27.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "We sent a code to",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10,),
                             Text(
                             '$Email!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Pinput(
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
                      ),

                      const SizedBox(height: 16.0),
                      SlideTransition(
                        position: _slideAnimation,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFD1493B),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, CupertinoPageRoute(builder: (context) => UpdatePassword(),));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    0,
                                    0,
                                    0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0,
                                    vertical: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Text(
                                  'Reset Password',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 40.0),
                      SlideTransition(
                        position: _slideAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Dont Recieve the email?',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.0,
                                  color: const Color.fromARGB(255, 11, 11, 11),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Click To Resend',
                              style: GoogleFonts.poppins(
                                fontSize: 14.0,
                                color: const Color.fromARGB(255, 11, 11, 11),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      size.height - 50,
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
