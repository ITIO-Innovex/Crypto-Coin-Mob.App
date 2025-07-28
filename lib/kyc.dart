import 'package:coincraze/Constants/Colors.dart';
import 'package:coincraze/HomeScreen.dart';
import 'package:coincraze/IdProffScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KYCScreen extends StatelessWidget {
  const KYCScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _fullNameController = TextEditingController();
    final _addressController = TextEditingController();
    final _phoneController = TextEditingController();
    //final _emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KYC Verification - 05:26 PM, 17 Jun 2025',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              // Progress Indicator with Line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep(context, "Personal info", true, 1),
                  Expanded(child: _buildProgressLine(0.5)),
                  _buildStep(context, "ID proof", false, 2),
                  Expanded(child: _buildProgressLine(0.0)),
                  _buildStep(context, "Bank details", false, 3),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'PERSONAL INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              // Full Name Field
              _buildTextField(
                label: 'FULL NAME',
                controller: _fullNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              // Home Address Field
              _buildTextField(
                label: 'HOME ADDRESS',
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              // Phone Number Field
              _buildTextField(
                label: 'PHONE NUMBER',
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              // Email Address Field
              // _buildTextField(
              //   label: 'EMAIL ADDRESS',
              //   controller: _emailController,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter your email address';
              //     }
              //     if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              //       return 'Please enter a valid email address';
              //     }
              //     return null;
              //   },
              // ),
              const SizedBox(height: 30),
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const IDProofScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black ?? const Color.fromARGB(255, 11, 11, 11),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // I'll do it later Button
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => Homescreen(),));
                  },
                  child: Text(
                    "I'LL DO IT LATER",
                    style: TextStyle(
                      color: AppColors.black ?? Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String title, bool isActive, int stepNumber) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? (AppColors.black ?? Colors.green) : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 24)
              : Text(
                  stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.grey.shade300,
        color: AppColors.black ?? Colors.green,
        minHeight: 3,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: controller.text,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        errorStyle: const TextStyle(color: Colors.redAccent),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}