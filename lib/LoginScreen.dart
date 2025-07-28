import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/ForgotPassword.dart';
import 'package:coincraze/SignUp.dart';
import 'package:coincraze/newKyc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
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
    _initAuthManager();
  }

  Future<void> _initAuthManager() async {
    await AuthManager().init();
    if (AuthManager().email != null) {
      setState(() {
        emailController.text = AuthManager().email!;
      });
    }
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

    try {
      print('Sending request to $ProductionBaseUrl/api/auth/login');
      final response = await http.post(
        Uri.parse('$ProductionBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final loginResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        await AuthManager().saveLoginDetails(loginResponse);
        print(
          'User data saved: Token = ${AuthManager().token}, UserId = ${AuthManager().userId}',
        );

        if (AuthManager().kycCompleted == true) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => NewKYC()),
          );
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

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool authenticated = await AuthManager().authenticateWithBiometrics();
      if (authenticated) {
        if (AuthManager().email != null) {
          setState(() {
            emailController.text = AuthManager().email!;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fingerprint verified. Please enter your password.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No stored email found. Please login manually first.',
              ),
              backgroundColor: const Color(0xFFD1493B),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed'),
            backgroundColor: const Color(0xFFD1493B),
          ),
        );
      }
    } catch (e) {
      print('Biometric login error: $e');
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

  Future<void> _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Implement social login logic here (e.g., using google_sign_in, firebase_auth, etc.)
      // Example: await AuthManager().signInWithProvider(provider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logging in with $provider...'),
          backgroundColor: Colors.green,
        ),
      );
      // Add navigation logic after successful login
    } catch (e) {
      print('Social login error: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/e.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.colorBurn,
            ),
          ),
          gradient: const LinearGradient(
            colors: [Color.fromARGB(255, 3, 4, 4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? screenWidth * 0.15 : 32.0,
                  vertical: isTablet ? 20.0 : 10.0,
                ),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Image.asset(
                        'assets/images/whtLogo.png',
                        width: isTablet ? 300 : 220,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.06),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        "LOGIN",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 30.0 : 27.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        "Login with email and password",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16.0 : 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    SlideTransition(
                      position: _slideAnimation,
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 18.0 : 16.0,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Colors.grey,
                          ),
                          hintText: 'Email',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isTablet ? 18.0 : 15.0,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    SlideTransition(
                      position: _slideAnimation,
                      child: TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 18.0 : 16.0,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          hintText: 'Password',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isTablet ? 18.0 : 15.0,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => ForgotPassword(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16.0 : 14.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    SlideTransition(
                      position: _slideAnimation,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFD1493B),
                              ),
                            )
                          : Column(
                              children: [
                                ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      0,
                                      0,
                                      0,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 40.0 : 32.0,
                                      vertical: isTablet ? 18.0 : 16.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        isTablet ? 18.0 : 15.0,
                                      ),
                                    ),
                                    minimumSize: Size(
                                      double.infinity,
                                      isTablet ? 55 : 50,
                                    ),
                                  ),
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: isTablet ? 18.0 : 16.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                // ElevatedButton(
                                //   onPressed: _handleBiometricLogin,
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: const Color.fromARGB(
                                //       255,
                                //       0,
                                //       0,
                                //       0,
                                //     ),
                                //     padding: EdgeInsets.symmetric(
                                //       horizontal: isTablet ? 40.0 : 32.0,
                                //       vertical: isTablet ? 18.0 : 16.0,
                                //     ),
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(
                                //         isTablet ? 18.0 : 15.0,
                                //       ),
                                //     ),
                                //     minimumSize: Size(
                                //       double.infinity,
                                //       isTablet ? 55 : 50,
                                //     ),
                                //   ),
                                //   child: Row(
                                //     mainAxisAlignment: MainAxisAlignment.center,
                                //     children: [
                                //       const Icon(
                                //         Icons.fingerprint,
                                //         color: Colors.white,
                                //         size: 24,
                                //       ),
                                //       const SizedBox(width: 8.0),
                                //       Text(
                                //         'Login with Fingerprint',
                                //         style: GoogleFonts.poppins(
                                //           fontSize: isTablet ? 18.0 : 16.0,
                                //           fontWeight: FontWeight.w600,
                                //           color: Colors.white,
                                //         ),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                              ],
                            ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Divider(color: Colors.blue,),
                          Text(
                            '-----------  OR LOGIN WITH  ----------',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16.0 : 14.0,
                              color: Colors.grey[400],
                            ),
                          ),
                          Divider(color: Colors.blue,),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.3,
                        ), 
                        borderRadius: BorderRadius.circular(20)// Semi-transparent white background
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SlideTransition(
                              position: _slideAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _handleSocialLogin('apple'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    child: const Icon(
                                      Icons.apple,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.04),
                                  ElevatedButton(
                                    onPressed: () => _handleSocialLogin('google'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    child: Image.asset(
                                      'assets/images/google_logo.png', // Add Google icon asset
                                      width: 18,
                                      height: 18,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.04),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _handleSocialLogin('facebook'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1877F2),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    child: const Icon(
                                      Icons.facebook,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16.0 : 14.0,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 16.0 : 14.0,
                                color: const Color.fromARGB(255, 250, 249, 249),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
