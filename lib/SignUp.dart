import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false; // New state for checkbox
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _emailShakeController;
  late AnimationController _phoneShakeController;
  late AnimationController _passwordShakeController;
  late AnimationController _confirmPasswordShakeController;
  late Animation<double> _emailShakeAnimation;
  late Animation<double> _phoneShakeAnimation;
  late Animation<double> _passwordShakeAnimation;
  late Animation<double> _confirmPasswordShakeAnimation;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

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

    _emailShakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _phoneShakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _passwordShakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _confirmPasswordShakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _emailShakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_emailShakeController);
    _phoneShakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_phoneShakeController);
    _passwordShakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_passwordShakeController);
    _confirmPasswordShakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_confirmPasswordShakeController);

    _emailFocus.addListener(_validateEmailOnFocusChange);
    _phoneFocus.addListener(_validatePhoneOnFocusChange);
    _passwordFocus.addListener(_validatePasswordOnFocusChange);
    _confirmPasswordFocus.addListener(_validateConfirmPasswordOnFocusChange);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailShakeController.dispose();
    _phoneShakeController.dispose();
    _passwordShakeController.dispose();
    _confirmPasswordShakeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _triggerShake(AnimationController controller) {
    controller.forward().then((_) => controller.reverse());
  }

  void _validateEmailOnFocusChange() {
    if (!_emailFocus.hasFocus) {
      final email = emailController.text.trim().toLowerCase();
      emailController.text = email;
      setState(() {
        if (email.isEmpty) {
          _emailError = 'Email is required';
          _triggerShake(_emailShakeController);
        } else if (!RegExp(
          r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$',
        ).hasMatch(email)) {
          _emailError = 'Please enter a valid email';
          _triggerShake(_emailShakeController);
        } else {
          _emailError = null;
        }
      });
    }
  }

  void _validatePhoneOnFocusChange() {
    if (!_phoneFocus.hasFocus) {
      final phone = phoneNumberController.text.trim();
      setState(() {
        if (phone.isEmpty) {
          _phoneError = 'Phone number is required';
          _triggerShake(_phoneShakeController);
        } else if (!RegExp(r'^\+?[0-9]{10,12}$').hasMatch(phone)) {
          _phoneError = 'Enter valid phone number';
          _triggerShake(_phoneShakeController);
        } else {
          _phoneError = null;
        }
      });
    }
  }

  void _validatePasswordOnFocusChange() {
    if (!_passwordFocus.hasFocus) {
      final pass = passwordController.text;
      setState(() {
        if (pass.isEmpty) {
          _passwordError = 'Password is required';
          _triggerShake(_passwordShakeController);
        } else if (pass.length < 8 ||
            !RegExp(
              r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
            ).hasMatch(pass)) {
          _passwordError = 'Weak password';
          _triggerShake(_passwordShakeController);
        } else {
          _passwordError = null;
        }
      });
    }
  }

  void _validateConfirmPasswordOnFocusChange() {
    if (!_confirmPasswordFocus.hasFocus) {
      final confirm = confirmPasswordController.text;
      final password = passwordController.text;
      setState(() {
        if (confirm.isEmpty) {
          _confirmPasswordError = 'Confirm password';
          _triggerShake(_confirmPasswordShakeController);
        } else if (password != confirm) {
          _confirmPasswordError = 'Passwords do not match';
          _triggerShake(_confirmPasswordShakeController);
        } else {
          _confirmPasswordError = null;
        }
      });
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);
    _validateEmailOnFocusChange();
    _validatePhoneOnFocusChange();
    _validatePasswordOnFocusChange();
    _validateConfirmPasswordOnFocusChange();

    if (!_agreeToTerms) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the Privacy Policy and Terms & Conditions',
          ),
          backgroundColor: Color(0xFFD1493B),
        ),
      );
      return;
    }

    if (_emailError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$ProductionBaseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'phoneNumber': phoneNumberController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Sign-up failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFD1493B),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFD1493B),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Animation<double> shakeAnimation,
    required String? errorText,
    bool isPassword = false,
    bool isTablet = false,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && _obscurePassword,
            keyboardType: isPassword
                ? TextInputType.visiblePassword
                : (hint.contains('Phone')
                      ? TextInputType.phone
                      : TextInputType.emailAddress),
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 18.0 : 16.0,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: _togglePasswordVisibility,
                    )
                  : null,
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTablet ? 18.0 : 15.0),
                borderSide: BorderSide.none,
              ),
              errorText: errorText,
            ),
          ),
        ),
      ),
    );
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
            image: const AssetImage('assets/images/sp.jpg'),
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
                    SizedBox(height: screenHeight * 0.01),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Text(
                        "SIGN UP",
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
                        "Create an account to get started",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16.0 : 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    _buildTextField(
                      hint: 'Email',
                      icon: Icons.email,
                      controller: emailController,
                      focusNode: _emailFocus,
                      shakeAnimation: _emailShakeAnimation,
                      errorText: _emailError,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      hint: '+91 Phone Number',
                      icon: Icons.phone,
                      controller: phoneNumberController,
                      focusNode: _phoneFocus,
                      shakeAnimation: _phoneShakeAnimation,
                      errorText: _phoneError,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      hint: 'Password',
                      icon: Icons.lock,
                      controller: passwordController,
                      focusNode: _passwordFocus,
                      shakeAnimation: _passwordShakeAnimation,
                      errorText: _passwordError,
                      isPassword: true,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    _buildTextField(
                      hint: 'Confirm Password',
                      icon: Icons.lock,
                      controller: confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      shakeAnimation: _confirmPasswordShakeAnimation,
                      errorText: _confirmPasswordError,
                      isPassword: true,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (bool? value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFFD1493B),
                              checkColor: Colors.white,
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 16.0 : 14.0,
                                    color: const Color.fromARGB(
                                      255,
                                      228,
                                      221,
                                      221,
                                    ),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 16.0 : 14.0,
                                        color: const Color.fromARGB(
                                          255,
                                          250,
                                          249,
                                          249,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          final Uri url = Uri.parse(
                                            'https://vikas-web.github.io/CoinCrazeLandingPage/privacy-policy.html',
                                          );
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(
                                              url,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not open Privacy Policy',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                    ),
                                    TextSpan(
                                      text: ' and ',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 16.0 : 14.0,
                                        color: const Color.fromARGB(
                                          255,
                                          228,
                                          221,
                                          221,
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 16.0 : 14.0,
                                        color: const Color.fromARGB(
                                          255,
                                          250,
                                          249,
                                          249,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                         ..onTap = () async {
                                          final Uri url = Uri.parse(
                                            'https://vikas-web.github.io/CoinCrazeLandingPage/privacy-policy.html',
                                          );
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(
                                              url,
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Could not open Terms And Condition',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                          : ElevatedButton(
                              onPressed: _handleSignUp,
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
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 18.0 : 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 16.0 : 14.0,
                                color: const Color.fromARGB(255, 228, 221, 221),
                              ),
                            ),
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
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 16.0 : 16.0,
                                  color: const Color.fromARGB(
                                    255,
                                    250,
                                    249,
                                    249,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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
