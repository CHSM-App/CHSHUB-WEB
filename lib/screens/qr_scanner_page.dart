import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool isScanned = false;
  bool isTorchOn = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _processQrData(String code) {
    if (isScanned) return;
    
    setState(() {
      isScanned = true;
    });

    // Parse QR data
    String otp = "";
    String name = "";
    String flat = "";
    
    final lines = code.split(RegExp(r'[\n\r]'));
    for (var line in lines) {
      if (line.contains("Guest:")) {
        name = line.replaceAll("Guest:", "").trim();
      } else if (line.contains("OTP:")) {
        otp = line.replaceAll("OTP:", "").trim();
      } else if (line.contains("Flat:")) {
        flat = line.replaceAll("Flat:", "").trim();
      }
    }

    // Show dialog with scanned data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("QR Code Scanned"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Guest", name),
            const SizedBox(height: 8),
            _buildInfoRow("OTP", otp),
            const SizedBox(height: 8),
            _buildInfoRow("Flat", flat),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() {
                isScanned = false;
              });
            },
            child: const Text("Scan Again"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {
                "otp": otp,
                "name": name,
                "flat": flat,
              }); // Return data
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? "Not found" : value,
            style: TextStyle(
              color: value.isEmpty ? Colors.red : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final BarcodeCapture? barcodes = await controller.analyzeImage(image.path);
      
      if (barcodes != null && barcodes.barcodes.isNotEmpty) {
        final code = barcodes.barcodes.first.rawValue ?? "";
        if (code.isNotEmpty) {
          _processQrData(code);
        } else {
          _showError("No QR code found in the image");
        }
      } else {
        _showError("No QR code found in the image");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        actions: [
          IconButton(
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : null,
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                isTorchOn = !isTorchOn;
              });
            },
            tooltip: "Toggle Torch",
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (isScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final code = barcodes.first.rawValue ?? "";
                if (code.isNotEmpty) {
                  _processQrData(code);
                }
              }
            },
          ),
          // Overlay with scanning area
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Align QR code within the frame",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _pickImageFromGallery,
      //   icon: const Icon(Icons.photo_library),
      //   label: const Text("Gallery"), 
      // ),
    );
  }
}