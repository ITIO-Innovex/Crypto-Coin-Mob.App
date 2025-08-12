import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
    setState(() {
      isPermissionGranted = status.isGranted;
    });

    if (!isPermissionGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  bool _isValidURL(String input) {
    final Uri? uri = Uri.tryParse(input);
    return uri != null && (uri.isScheme("http") || uri.isScheme("https"));
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
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

      if (result.rawContent.isNotEmpty) {
        setState(() {
          scannedWalletAddress = result.rawContent;
        });

        if (_isValidURL(result.rawContent)) {
          await _launchURL(result.rawContent);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned: ${result.rawContent}')),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context, scannedWalletAddress);
        });
      } else {
        setState(() {
          isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan cancelled or no data')),
        );
      }
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection cancelled')),
      );
      return;
    }

    setState(() {
      isScanning = true;
    });

    try {
      var result = await BarcodeScanner.scan(
        options: ScanOptions(restrictFormat: [BarcodeFormat.qr]),
      );

      if (result.rawContent.isNotEmpty) {
        setState(() {
          scannedWalletAddress = result.rawContent;
        });

        if (_isValidURL(result.rawContent)) {
          await _launchURL(result.rawContent);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned from gallery: ${result.rawContent}')),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context, scannedWalletAddress);
        });
      } else {
        setState(() {
          isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No QR code found in image')),
        );
      }
    } catch (e) {
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
