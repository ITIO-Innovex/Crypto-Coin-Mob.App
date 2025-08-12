import 'package:coincraze/Constants/API.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'dart:convert';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();
  late Box _hiveBox;

  String? _firstName;
  String? _lastName;
  String? _dob;
  String? _phone;
  String? _country;
  String? _documentType;
  String? _frontImagePath;
  String? _backImagePath;
  String? _bankName;
  String? _accountNumber;
  String? _ifsc;
  String? _userId;
  String? _email;
  String? _phoneNumber;
  bool? _kycCompleted;
  String? _token;
  bool _isLoggedIn = false;
  String? _profilePicture;
  String? _lastLoginTime;
  int? _loginCount;

  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get dob => _dob;
  String? get phone => _phone;
  String? get country => _country;
  String? get documentType => _documentType;
  String? get frontImagePath => _frontImagePath;
  String? get backImagePath => _backImagePath;
  String? get bankName => _bankName;
  String? get accountNumber => _accountNumber;
  String? get ifsc => _ifsc;
  String? get userId => _userId;
  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  bool? get kycCompleted => _kycCompleted;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  String? get profilePicture => _profilePicture;
  String? get lastLoginTime => _lastLoginTime;
  int? get loginCount => _loginCount;

  Future<void> init() async {
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox('authBox');
    await loadSavedDetails();
  }

  Future<void> saveLoginDetails(Map<String, dynamic> loginResponse) async {
    try {
      if (loginResponse['user'] == null || loginResponse['token'] == null) {
        throw Exception('Invalid login response format');
      }

      final user = loginResponse['user'] as Map<String, dynamic>;
      final kyc = user['kyc'] as Map<String, dynamic>?;
      final personalInfo = kyc?['personalInfo'] as Map<String, dynamic>?;
      final idProof = kyc?['idProof'] as Map<String, dynamic>?;
      final bankDetails = kyc?['bankDetails'] as Map<String, dynamic>?;

      _firstName = personalInfo?['FirstName']?.toString();
      _lastName = personalInfo?['LastName']?.toString();
      _dob = personalInfo?['dob']?.toString();
      _phone = personalInfo?['phone']?.toString();
      _country = idProof?['country']?.toString();
      _documentType = idProof?['documentType']?.toString();
      _frontImagePath = idProof?['frontImagePath']?.toString();
      _backImagePath = idProof?['backImagePath']?.toString();
      _bankName = bankDetails?['bankName']?.toString();
      _accountNumber = bankDetails?['accountNumber']?.toString();
      _ifsc = bankDetails?['ifsc']?.toString();
      _userId = user['_id']?.toString();
      _email = user['email']?.toString();
      _phoneNumber = user['phoneNumber']?.toString();
      _kycCompleted = kyc?['kycCompleted'] as bool? ?? false;
      _profilePicture = user['profilePicture']?.toString();
      _token = loginResponse['token']?.toString();
      _isLoggedIn = true;

      await Future.wait([
        _storage.write(key: 'firstName', value: _firstName),
        _storage.write(key: 'lastName', value: _lastName),
        _storage.write(key: 'dob', value: _dob),
        _storage.write(key: 'phone', value: _phone),
        _storage.write(key: 'country', value: _country),
        _storage.write(key: 'documentType', value: _documentType),
        _storage.write(key: 'frontImagePath', value: _frontImagePath),
        _storage.write(key: 'backImagePath', value: _backImagePath),
        _storage.write(key: 'bankName', value: _bankName),
        _storage.write(key: 'accountNumber', value: _accountNumber),
        _storage.write(key: 'ifsc', value: _ifsc),
        _storage.write(key: 'userId', value: _userId),
        _storage.write(key: 'email', value: _email),
        _storage.write(key: 'phoneNumber', value: _phoneNumber),
        _storage.write(key: 'kycCompleted', value: _kycCompleted.toString()),
        _storage.write(key: 'profilePicture', value: _profilePicture),
        _storage.write(key: 'token', value: _token),
        _storage.write(key: 'isLoggedIn', value: _isLoggedIn.toString()),
      ]);

      _lastLoginTime = DateTime.now().toIso8601String();
      _loginCount = (_hiveBox.get('loginCount') as int? ?? 0) + 1;
      await _hiveBox.put('lastLoginTime', _lastLoginTime);
      await _hiveBox.put('loginCount', _loginCount);
    } catch (e) {
      print('Error saving login details: $e');
      throw e;
    }
  }

  Future<void> loadSavedDetails() async {
    try {
      await Future.wait([
        _storage.read(key: 'firstName').then((value) => _firstName = value),
        _storage.read(key: 'lastName').then((value) => _lastName = value),
        _storage.read(key: 'dob').then((value) => _dob = value),
        _storage.read(key: 'phone').then((value) => _phone = value),
        _storage.read(key: 'country').then((value) => _country = value),
        _storage.read(key: 'documentType').then((value) => _documentType = value),
        _storage.read(key: 'frontImagePath').then((value) => _frontImagePath = value),
        _storage.read(key: 'backImagePath').then((value) => _backImagePath = value),
        _storage.read(key: 'bankName').then((value) => _bankName = value),
        _storage.read(key: 'accountNumber').then((value) => _accountNumber = value),
        _storage.read(key: 'ifsc').then((value) => _ifsc = value),
        _storage.read(key: 'userId').then((value) => _userId = value),
        _storage.read(key: 'email').then((value) => _email = value),
        _storage.read(key: 'phoneNumber').then((value) => _phoneNumber = value),
        _storage.read(key: 'kycCompleted').then((value) => _kycCompleted = value == 'true'),
        _storage.read(key: 'profilePicture').then((value) => _profilePicture = value),
        _storage.read(key: 'token').then((value) => _token = value),
        _storage.read(key: 'isLoggedIn').then((value) => _isLoggedIn = value == 'true'),
      ]);

      _lastLoginTime = _hiveBox.get('lastLoginTime') as String?;
      _loginCount = _hiveBox.get('loginCount') as int?;
    } catch (e) {
      print('Error loading saved details: $e');
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        print('Biometrics not available or not supported on this device');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate with fingerprint to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await clearUserData();
  }

  Future<void> clearUserData() async {
    try {
      await _storage.deleteAll();
      await _hiveBox.clear();
      _firstName = null;
      _lastName = null;
      _dob = null;
      _phone = null;
      _country = null;
      _documentType = null;
      _frontImagePath = null;
      _backImagePath = null;
      _bankName = null;
      _accountNumber = null;
      _ifsc = null;
      _userId = null;
      _email = null;
      _phoneNumber = null;
      _kycCompleted = null;
      _profilePicture = null;
      _token = null;
      _isLoggedIn = false;
      _lastLoginTime = null;
      _loginCount = null;
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  Future<String?> uploadProfilePicture(String userId, String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$ProductionBaseUrl/api/profile/upload-profile-picture'),
      );
      request.fields['userId'] = userId;
      request.files.add(await http.MultipartFile.fromPath('profilePicture', filePath));
      request.headers['Authorization'] = 'Bearer $_token';

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final jsonData = jsonDecode(responseData.body);

      if (response.statusCode == 200 && jsonData['profilePicturePath'] != null) {
        _profilePicture = jsonData['profilePicturePath'];
        await _storage.write(key: 'profilePicture', value: _profilePicture);
        return _profilePicture;
      } else {
        print('Upload failed: ${jsonData['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<String?> getAuthToken() async {
    return _token ?? await _storage.read(key: 'token');
  }
}