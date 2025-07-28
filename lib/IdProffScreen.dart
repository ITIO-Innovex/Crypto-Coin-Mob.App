import 'package:coincraze/BankDetailsScreen.dart';
import 'package:coincraze/Constants/Colors.dart';
import 'package:flutter/material.dart';

class IDProofScreen extends StatelessWidget {
  const IDProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String? _selectedCountry;
    String? _selectedDocType;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KYC Verification - 05:36 PM, 17 Jun 2025',
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
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator with Line
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStep(context, "Personal info", true, 1),
                    Expanded(child: _buildProgressLine(1.0)),
                    _buildStep(context, "ID proof", true, 2),
                    Expanded(child: _buildProgressLine(0.0)),
                    _buildStep(context, "Bank details", false, 3),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Upload a proof of your identity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Apex Markets requires a valid government-issued ID (driver’s license, passport, national ID)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                // Country Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Your country',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'India', child: Text('India')),
                    DropdownMenuItem(value: 'USA', child: Text('USA')),
                    DropdownMenuItem(value: 'UK', child: Text('UK')),
                  ],
                  onChanged: (value) {
                    _selectedCountry = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your country';
                    }
                    return null;
                  },
                  hint: const Text('Select your country'),
                ),
                const SizedBox(height: 15),
                // Document Type Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Document type',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                    DropdownMenuItem(value: 'Driver\'s License', child: Text('Driver\'s License')),
                    DropdownMenuItem(value: 'National ID', child: Text('National ID')),
                  ],
                  onChanged: (value) {
                    _selectedDocType = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a document type';
                    }
                    return null;
                  },
                  hint: const Text('Select a document type'),
                ),
                const SizedBox(height: 20),
                // Front and Back Upload Sections
                Row(
                  children: [
                    Expanded(
                      child: _buildUploadSection('Front side of your document', 'Supports JPG, PNG, PDF'),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildUploadSection('Back side of your document', 'Supports JPG, PNG, PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'I confirm that the uploaded file is a valid government-issued photo ID. This ID includes my picture, signature, name, date of birth, and address.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BankDetailsScreen()),
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
              ],
            ),
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

  Widget _buildUploadSection(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Choose a File',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}