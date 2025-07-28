import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/VerifyOtp.dart';
import 'package:coincraze/newKyc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

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
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text;

    // Client-side validation
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: const Color(0xFFD1493B),
        ),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: const Color(0xFFD1493B),
        ),
      );
      return;
    }

    // API call to backend
    try {
      print('Sending request to $ProductionBaseUrl');
      final response = await http.post(
        Uri.parse('$ProductionBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final loginResponse = json.decode(
        response.body,
      ); // Define loginResponse here

      if (response.statusCode == 200) {
        await AuthManager().saveLoginDetails(loginResponse);
        print(
          'User data saved: Email = ${AuthManager().email}, UserId = ${AuthManager().userId}',
        ); // Save all details

        // Navigate to Kyc Screen
        if (AuthManager().kycCompleted == true) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => NewKYC()));
        }
      } else {
        final error = loginResponse['error'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFD1493B),
          ),
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFD1493B),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          "Change Password",
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
                        child: Text(
                          "No worries, we'll send you reset instructions",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      SlideTransition(
                        position: _slideAnimation,
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.grey,
                            ),
                            hintText: 'Enter Your Password',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15,),
                      SlideTransition(
                        position: _slideAnimation,
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.grey,
                            ),
                            hintText: 'Confirm Password',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
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
                                onPressed: (){
                                  Navigator.push(context, CupertinoPageRoute(builder: (context) => VerifyOtp(),));
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
                            Icon(Icons.arrow_back),
                            SizedBox(width: 15),
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
                                'Back To Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.0,
                                  color: const Color.fromARGB(255, 11, 11, 11),
                                  fontWeight: FontWeight.w600,
                                ),
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
