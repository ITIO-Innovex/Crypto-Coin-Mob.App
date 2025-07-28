import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Constants/Colors.dart';
import 'package:coincraze/HomeScreen.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class NewKYC extends StatefulWidget {
  const NewKYC({super.key});

  @override
  _NewKYCState createState() => _NewKYCState();
}

class _NewKYCState extends State<NewKYC> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _formKeys = List.generate(3, (index) => GlobalKey<FormState>());
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountry = 'India';
  String _selectedDocumentType = 'Aadhaar';
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  late AnimationController _animationController;
  String? _selectedBank;

  // Static list of Indian banks with sample full IFSC codes (11 characters)
  final Map<String, String> bankIfscMap = {
    'State Bank of India': 'SBIN0000123',
    'HDFC Bank': 'HDFC0004567',
    'ICICI Bank': 'ICIC0007890',
    'Axis Bank': 'UTIB0001234',
    'Punjab National Bank': 'PUNB0525610',
    'Bank of Baroda': 'BARB0VJ1234',
    'Canara Bank': 'CNRB0005678',
    'Union Bank of India': 'UBIN0567890',
    'Kotak Mahindra Bank': 'KKBK0000123',
    'Yes Bank': 'YESB0004567',
    'IDBI Bank': 'IBKL0007890',
    'Bank of India': 'BKID0001234',
    'Central Bank of India': 'CBIN0285678',
    'Indian Bank': 'IDIB0009012',
    'Syndicate Bank': 'SYNB0003456',
    'Allahabad Bank': 'ALLA0217890',
    'Andhra Bank': 'ANDB0001234',
    'Bank of Maharashtra': 'MAHB0005678',
    'Corporation Bank': 'CORP0009012',
    'Dena Bank': 'BKDN0523456',
    'Indian Overseas Bank': 'IOBA0007890',
    'Oriental Bank of Commerce': 'ORBC0101234',
    'UCO Bank': 'UCBA0005678',
    'Vijaya Bank': 'VIJB0009012',
    'Federal Bank': 'FDRL0003456',
    'South Indian Bank': 'SIBL0007890',
    'Karur Vysya Bank': 'KVBL0001234',
    'City Union Bank': 'CIUB0005678',
    'IndusInd Bank': 'INDB0009012',
    'RBL Bank': 'RATN0003456',
    'Bandhan Bank': 'BDBL0007890',
    'IDFC First Bank': 'IDFB0045678',
    'DCB Bank': 'DCBL0001234',
    'Tamilnad Mercantile Bank': 'TMBL0009012',
    'Lakshmi Vilas Bank': 'LAVB0003456',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    AuthManager().init().then((_) {
      AuthManager().loadSavedDetails();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitKYCData() async {
    final userId = AuthManager().userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User not logged in! Please log in again.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final email = AuthManager().email;
    final phoneNumber = AuthManager().phoneNumber;

    if (email == null || phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User profile incomplete. Please ensure email and phone number are set.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final personalInfo = {
        'FirstName': _firstNameController.text.trim(),
        'LastName': _lastNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      final idProof = {
        'country': _selectedCountry,
        'documentType': _selectedDocumentType,
      };
      final bankDetails = {
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'ifsc': _ifscController.text.trim(),
      };

      final token = await AuthManager().getAuthToken();
      if(token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authentication token not found. Please log in again.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$ProductionBaseUrl/api/kyc/submit-kyc'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['userId'] = userId;
      request.fields['personalInfo'] = jsonEncode(personalInfo);
      request.fields['idProof'] = jsonEncode(idProof);
      request.fields['bankDetails'] = jsonEncode(bankDetails);

      if (_frontImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('frontImage', _frontImage!.path),
        );
      }
      if (_backImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('backImage', _backImage!.path),
        );
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final loginDetails = {
          'user': {
            '_id': userId,
            'email': email,
            'phoneNumber': phoneNumber,
            'kyc': {
              'kycCompleted': true,
              'personalInfo': personalInfo,
              'idProof': idProof,
              'bankDetails': bankDetails,
            },
          },
          'token': token, // Include token to satisfy AuthManager
        };

        // Log for debugging
        print('Saving login details: ${jsonEncode(loginDetails)}');

        try {
          await AuthManager().saveLoginDetails(loginDetails);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'KYC submitted successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => MainScreen()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save login details: ${e.toString()}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        String errorMessage = 'Failed to submit KYC';
        try {
          final errorData = jsonDecode(responseData.body);
          errorMessage = errorData['message'] ?? responseData.body;
        } catch (_) {
          errorMessage = responseData.body.isNotEmpty ? responseData.body : 'Unknown server error';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error submitting KYC: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenWidth < 600;
    final double fontScale = isSmallScreen ? 0.9 : 1.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87, size: 24 * fontScale),
          onPressed: () => Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => LoginScreen(),)),
        ),
        title: Text(
          'KYC Verification',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 22 * fontScale,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - kToolbarHeight - MediaQuery.of(context).padding.top,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStep(context, "Personal Info", _currentStep >= 0, 1),
                    Expanded(
                      child: _buildProgressLine(_currentStep >= 1 ? 1.0 : 0.0),
                    ),
                    _buildStep(context, "ID Proof", _currentStep >= 1, 2),
                    Expanded(
                      child: _buildProgressLine(_currentStep >= 2 ? 1.0 : 0.0),
                    ),
                    _buildStep(context, "Bank Details", _currentStep >= 2, 3),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _currentStep == 0
                      ? 'Personal Information'
                      : _currentStep == 1
                          ? 'ID Proof'
                          : 'Bank Details',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 24 * fontScale,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: _buildStepContent(screenWidth),
              ),
              SizedBox(height: screenHeight * 0.03),
              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKeys[_currentStep].currentState!.validate()) {
                        if (_currentStep == 1 && (_frontImage == null || _backImage == null)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please upload both front and back images',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        if (_currentStep < 2) {
                          setState(() {
                            _currentStep += 1;
                            _animationController.forward(from: 0);
                          });
                        } else {
                          _submitKYCData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black ?? Colors.black87,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.025,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      _currentStep == 2 ? 'Submit' : 'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(builder: (context) => MainScreen()),
                      );
                    },
                    child: Text(
                      "I'll Do It Later",
                      style: GoogleFonts.poppins(
                        color: AppColors.black ?? Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 16 * fontScale,
                      ),
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

  Widget _buildStep(
    BuildContext context,
    String title,
    bool isActive,
    int stepNumber,
  ) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? (AppColors.black ?? Colors.black87) : Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Text(
                    stepNumber.toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 4,
        decoration: BoxDecoration(
          color: progress > 0 ? (AppColors.black ?? Colors.black87) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
    Color? fillColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        enabled: enabled,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          errorStyle: GoogleFonts.poppins(color: Colors.redAccent),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: AppColors.black ?? Colors.black87,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildBankDropdown(double screenWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedBank,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          labelText: 'Bank Name',
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
        items: bankIfscMap.keys.map((String bank) {
          return DropdownMenuItem<String>(
            value: bank,
            child: Text(bank, style: GoogleFonts.poppins()),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedBank = newValue;
            _bankNameController.text = newValue ?? '';
            _ifscController.text = newValue != null ? bankIfscMap[newValue]! : '';
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please select your bank';
          }
          return null;
        },
        isExpanded: true,
        dropdownColor: Colors.white,
        menuMaxHeight: screenWidth * 0.6,
      ),
    );
  }

  Widget _buildStepContent(double screenWidth) {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            children: [
              _buildTextField(
                label: 'First Name',
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Last Name',
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Date of Birth (DD/MM/YYYY)',
                controller: _dobController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your date of birth';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty || value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    labelText: 'Country',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                  items: ['India', 'USA', 'UK']
                      .map(
                        (country) => DropdownMenuItem(
                          value: country,
                          child: Text(country, style: GoogleFonts.poppins()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    labelText: 'Document Type',
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                  items: ['Aadhaar', 'Passport', 'Driving License']
                      .map(
                        (docType) => DropdownMenuItem(
                          value: docType,
                          child: Text(docType, style: GoogleFonts.poppins()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocumentType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(true),
                      icon: const Icon(Icons.upload_file, size: 20),
                      label: Text(
                        'Front Image',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black ?? Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                  if (_frontImage != null) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _frontImage!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: const Icon(Icons.upload_file, size: 20),
                      label: Text(
                        'Back Image',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black ?? Colors.black87,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                  if (_backImage != null) ...[
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _backImage!,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            children: [
              _buildBankDropdown(screenWidth),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Account Number',
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'IFSC Code',
                controller: _ifscController,
                enabled: false,
                fillColor: Colors.grey.shade200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select a bank to auto-fill IFSC code';
                  }
                  return null;
                },
              ),
            ],
          ),
        );
      default:
        return Container();
    }
  }
}