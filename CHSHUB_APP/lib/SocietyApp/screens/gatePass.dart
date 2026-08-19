import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';
class GatePassScreen extends ConsumerStatefulWidget {
  final String guestName;
  final String otp;
  final String flatNo;

  const GatePassScreen({
    super.key,
    required this.guestName,
    required this.otp,
    required this.flatNo,
  });

  @override
  ConsumerState<GatePassScreen> createState() => _GatePassScreenState();
}

class _GatePassScreenState extends ConsumerState<GatePassScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

Future<void> _downloadPassToDownloads(BuildContext context) async {
  try {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;

    final fileName =
        "${widget.guestName}_GatePass_${widget.otp}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png";

    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/Download");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final filePath = "${directory.path}/$fileName";
    final file = File(filePath);
    await file.writeAsBytes(image);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("GatePass saved in Downloads: $filePath")),
      );
    }
  } catch (e) {
    debugPrint("Download error: $e");
  }
}



  Future<void> _sharePass(BuildContext context) async {
    try {
      final Uint8List? image = await screenshotController.capture();
      if (image == null) return;

      final fileName = "${widget.guestName}_GatePass_${widget.otp}.png";
      final directory = await getTemporaryDirectory();
      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: "Here is the GatePass for ${widget.guestName} (Flat: ${widget.flatNo}, OTP: ${widget.otp})",
      );
    } catch (e) {
      debugPrint("Share error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData =
        "Guest: ${widget.guestName}\nOTP: ${widget.otp}\nFlat: ${widget.flatNo}";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        // title: Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: const [
        //     Icon(Icons.door_front_door_outlined, color: Colors.white),
        //     SizedBox(width: 8),
        //     Text(
        //       "GATEAPP",
        //       style: TextStyle(
        //         fontWeight: FontWeight.bold,
        //         letterSpacing: 1.5,
        //         color: Colors.white,
        //       ),
        //     ),
        //   ],
        // ),
        centerTitle: true,
       
  //       leading: IconButton(
  //         icon: const Icon(Icons.close, color: Colors.white),
  //         onPressed: () { Navigator.pop(context);
  // ref.read(visitorViewModelProvider.notifier).getVisitorList("byflat", ref.watch(basicInfoViewModelProvider).flatId??0);

     
  //         }
  //       ),
  leading: IconButton(
  icon: const Icon(Icons.close, color: Colors.white),
  onPressed: () {
    // Visitor list refresh (safe read)
    final info = ref.read(basicInfoViewModelProvider);
    ref
        .read(visitorViewModelProvider.notifier)
        .getVisitorList("byflat", info.flatId ?? 0);

    // Go back to BottomNav root screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  },
),

      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          double qrSize = constraints.maxWidth * 0.5;
          if (constraints.maxWidth > 600) qrSize = 300;

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Screenshot(
                      controller: screenshotController,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "GatePass",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 20),
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: qrSize,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 30),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [Colors.black87, Colors.black54],
                                ),
                              ),
                              child: Text(
                                widget.otp,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Show QR Code or tell OTP to guard",
                              style: TextStyle(color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                            Divider(
                              height: 40,
                              color: Colors.grey[300],
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                            Text(
                              widget.guestName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Guest at ${widget.flatNo}",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sharePass(context),
                        icon: const Icon(Icons.share, color: Colors.black),
                        label: const Text("Share",
                            style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadPassToDownloads(context),
                        icon: const Icon(Icons.download, color: Colors.black),
                        label: const Text("Download",
                            style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}
