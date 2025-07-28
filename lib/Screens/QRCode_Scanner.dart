import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String? scannedWalletAddress;
  bool isPermissionGranted = false;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      print('Camera permission granted');
    } else {
      print('Camera permission denied or restricted: $status');
    }
    setState(() {
      isPermissionGranted = status.isGranted;
    });
    if (!isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  Future<void> _scanQRCode() async {
    if (!isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required to scan')),
      );
      return;
    }

    setState(() {
      isScanning = true;
    });
    print('Starting QR scan...');

    try {
      var result = await BarcodeScanner.scan(
        options: ScanOptions(
          restrictFormat: [BarcodeFormat.qr],
          useCamera: -1,
          autoEnableFlash: false,
          android: const AndroidOptions(
            useAutoFocus: true,
            aspectTolerance: 0.5,
          ),
        ),
      );

      print('Scan result: ${result.rawContent}');

      if (result.rawContent.isNotEmpty) {
        setState(() {
          scannedWalletAddress = result.rawContent;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned: ${result.rawContent}')),
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context, scannedWalletAddress);
        });
      } else {
        print('Scan cancelled or empty');
        setState(() {
          isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan cancelled or no data')),
        );
      }
    } catch (e) {
      print('Error scanning QR code: $e');
      setState(() {
        isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan QR code: $e')),
      );
    }
  }

  Future<void> _uploadFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      print('Gallery selection cancelled');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection cancelled')),
      );
      return;
    }

    setState(() {
      isScanning = true;
    });
    print('Processing image from gallery: ${pickedFile.path}');

    try {
      var result = await BarcodeScanner.scan(
        options: ScanOptions(restrictFormat: [BarcodeFormat.qr]),
      );

      print('Gallery scan result: ${result.rawContent}');

      if (result.rawContent.isNotEmpty) {
        setState(() {
          scannedWalletAddress = result.rawContent;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned from gallery: ${result.rawContent}')),
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context, scannedWalletAddress);
        });
      } else {
        print('No QR code found in image');
        setState(() {
          isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in image')),
        );
      }
    } catch (e) {
      print('Error scanning image from gallery: $e');
      setState(() {
        isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Wallet QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use scanner UI to toggle flash')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Center(
              child: isPermissionGranted
                  ? isScanning
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _scanQRCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'Start QR Scan',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _uploadFromGallery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 15,
                                ),
                              ),
                              child: const Text(
                                'Upload from Gallery',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                  : const Text('Camera permission not granted'),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                scannedWalletAddress ?? 'Scan a QR Code',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}