import 'package:coincraze/Constants/Colors.dart';
import 'package:flutter/material.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  _BankDetailsScreenState createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
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

  String? selectedBank;
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  @override
  void dispose() {
    _ifscController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600; // Threshold for small screens
    final double padding = isSmallScreen ? 12.0 : 16.0;
    final double fontScale = isSmallScreen ? 0.9 : 1.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24 * fontScale),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'KYC Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20 * fontScale,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey.shade100,
          padding: EdgeInsets.all(padding),
          constraints: BoxConstraints(
            minHeight: screenSize.height, // Ensure full height on all screens
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator with Line (unchanged Row as requested)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep(context, "Personal info", true, 1, fontScale),
                  Expanded(child: _buildProgressLine(1.0, screenSize.width * 0.3)),
                  _buildStep(context, "ID proof", true, 2, fontScale),
                  Expanded(child: _buildProgressLine(1.0, screenSize.width * 0.3)),
                  _buildStep(context, "Bank details", true, 3, fontScale),
                ],
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),
              Text(
                'BANK DETAILS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18 * fontScale,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isSmallScreen ? 10 : 15),
              // Bank Name Dropdown
              _buildBankDropdown(fontScale, screenSize.width),
              SizedBox(height: isSmallScreen ? 10 : 15),
              // Account Number Field
              _buildTextField(
                'ACCOUNT NUMBER',
                'Enter your account number',
                controller: _accountNumberController,
                fontScale: fontScale,
              ),
              SizedBox(height: isSmallScreen ? 10 : 15),
              // IFSC Code Field (Grey background, always unselectable)
              _buildTextField(
                'IFSC CODE',
                'IFSC code will be auto-filled',
                controller: _ifscController,
                enabled: false, // Always unselectable
                fillColor: Colors.grey.shade200, // Grey background
                fontScale: fontScale,
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedBank == null ||
                        _accountNumberController.text.isEmpty ||
                        _ifscController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    // Handle KYC submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('KYC Submitted Successfully!')),
                    );
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black ?? const Color.fromARGB(255, 11, 11, 11),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 10 : 15),
              // I'll do it later Button
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "I'LL DO IT LATER",
                    style: TextStyle(
                      color: AppColors.black ?? Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 14 * fontScale,
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

  Widget _buildStep(BuildContext context, String title, bool isActive, int stepNumber, double fontScale) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20 * fontScale,
          backgroundColor: isActive ? (AppColors.black ?? Colors.green) : Colors.grey.shade300,
          child: isActive
              ? Icon(Icons.check, color: Colors.white, size: 24 * fontScale)
              : Text(
                  stepNumber.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * fontScale,
                  ),
                ),
        ),
        SizedBox(height: 8 * fontScale),
        Text(
          title,
          style: TextStyle(
            fontSize: 14 * fontScale,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(double progress, double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: width,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          color: AppColors.black ?? Colors.green,
          minHeight: 3,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    TextEditingController? controller,
    bool readOnly = false,
    bool enabled = true,
    Color? fillColor,
    required double fontScale,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: fillColor ?? Colors.white,
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14 * fontScale,
        ),
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14 * fontScale),
        contentPadding: EdgeInsets.symmetric(
          vertical: 18 * fontScale,
          horizontal: 16 * fontScale,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBankDropdown(double fontScale, double screenWidth) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        labelText: 'BANK NAME',
        hintText: 'Select your bank',
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14 * fontScale,
        ),
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14 * fontScale),
        contentPadding: EdgeInsets.symmetric(
          vertical: 18 * fontScale,
          horizontal: 16 * fontScale,
        ),
      ),
      value: selectedBank,
      items: bankIfscMap.keys.map((String bank) {
        return DropdownMenuItem<String>(
          value: bank,
          child: Text(
            bank,
            style: TextStyle(fontSize: 14 * fontScale),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedBank = newValue;
          _ifscController.text = newValue != null ? bankIfscMap[newValue]! : '';
        });
      },
      isExpanded: true,
      dropdownColor: Colors.white,
      menuMaxHeight: screenWidth * 0.6,
    );
  }
}