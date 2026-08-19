import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class PaymentSuccessPage extends ConsumerStatefulWidget {
  final int receiptId;
  const PaymentSuccessPage({super.key, required this.receiptId});

  @override
  ConsumerState<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends ConsumerState<PaymentSuccessPage> {
  @override
  void initState() {
    super.initState();
   _loadData();
  }
  Future<void> _loadData() async {
 Future.microtask(() {
      ref
          .read(dueHistoryViewModelProvider.notifier)
          .loadReceipt(widget.receiptId);
    });
}

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(dueHistoryViewModelProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final ScrollController horizontalController = ScrollController();
    final ScrollController verticalController = ScrollController();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: receiptState.receipt.when(
        data: (receipts) {
          if (receipts.isEmpty) {
            return const Center(child: Text("No receipt found"));
          }

          double totalAmount = receipts.isNotEmpty
              ? (receipts[0].paidAmount ?? 0.0)
              : 0.0;

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  constraints: const BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success Header
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50),
                              size: 56,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          Text(
                            "Payment Successful!",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${receipts.length} ${receipts.length > 1 ? "bills" : "bill"} paid successfully",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Payment Details
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Payment Details",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      _buildDetail(
                        "Name",
                        receipts[0].name ?? "-",
                        isSmallScreen,
                      ),
                      _buildDetail(
                        "Flat No",
                        receipts[0].unit ?? "-",
                        isSmallScreen,
                      ),
                      // _buildDetail("Date", receipts[0].date ?? "-", isSmallScreen),
                      _buildDetail(
                        "Date",
                        receipts[0].date != null
                            ? DateFormat(
                                'd MMM yyyy',
                              ).format(DateTime.parse(receipts[0].date!))
                            : "-",
                        isSmallScreen,
                      ),

                      _buildDetail(
                        "Payment Mode",
                        receipts[0].payMode ?? "-",
                        isSmallScreen,
                      ),
                      Divider(height: isSmallScreen ? 20 : 24),

                      // Bills Paid Table
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Bills Paid",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      Scrollbar(
                        controller: horizontalController,
                        thumbVisibility: true, // 👈 Always show scrollbar thumb
                        trackVisibility: true, // 👈 Optional: show track
                        child: SingleChildScrollView(
                          controller: horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            width: 480, // Adjust as needed
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // ✅ Table Header
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 10 : 12,
                                    horizontal: isSmallScreen ? 8 : 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF45A049),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.all(Radius.circular(5)
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: isSmallScreen ? 25 : 30,
                                        child: Text(
                                          "Sr",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: isSmallScreen ? 2 : 3,
                                        child: Text(
                                          "Bill No",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: isSmallScreen ? 2 : 3,
                                        child: Text(
                                          "Ref No",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "Status",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 9 : 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: isSmallScreen ? 2 : 3,
                                        child: Text(
                                          "Amount",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ✅ Vertical scroll (inside horizontal)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: screenWidth < 380 ? 200 : 300,
                                  ),
                                  child: Scrollbar(
                                    controller: verticalController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: verticalController,
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children: receipts.asMap().entries.map((
                                          entry,
                                        ) {
                                          int index = entry.key;
                                          DueHistory r = entry.value;
                                          bool isEven = index % 2 == 0;

                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: isSmallScreen ? 10 : 12,
                                              horizontal: isSmallScreen
                                                  ? 8
                                                  : 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isEven
                                                  ? const Color(0xFFF9FAFB)
                                                  : Colors.white,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color:
                                                      index ==
                                                          receipts.length - 1
                                                      ? Colors.transparent
                                                      : const Color(0xFFE5E7EB),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: isSmallScreen
                                                      ? 25
                                                      : 30,
                                                  child: Container(
                                                    width: isSmallScreen
                                                        ? 20
                                                        : 24,
                                                    height: isSmallScreen
                                                        ? 20
                                                        : 24,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF4CAF50,
                                                      ).withOpacity(0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "${index + 1}",
                                                        style: TextStyle(
                                                          fontSize:
                                                              isSmallScreen
                                                              ? 10
                                                              : 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                            0xFF4CAF50,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: isSmallScreen ? 2 : 3,
                                                  child: Text(
                                                    r.billno ?? "-",
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen
                                                          ? 10
                                                          : 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF1F2937,
                                                      ),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: isSmallScreen ? 2 : 3,
                                                  child: Text(
                                                    r.billRef ?? "-",
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen
                                                          ? 10
                                                          : 12,
                                                      color: const Color(
                                                        0xFF6B7280,
                                                      ),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                isSmallScreen
                                                                ? 3
                                                                : 4,
                                                            horizontal:
                                                                isSmallScreen
                                                                ? 6
                                                                : 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF10B981,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "PAID",
                                                        style: TextStyle(
                                                          fontSize:
                                                              isSmallScreen
                                                              ? 8
                                                              : 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: isSmallScreen ? 2 : 3,
                                                  child: Text(
                                                    "₹${r.amount?.toStringAsFixed(2) ?? "0.00"}",
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(
                                                      fontSize: isSmallScreen
                                                          ? 11
                                                          : 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF059669,
                                                      ),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Divider(height: isSmallScreen ? 20 : 24),

                      // Total Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "Total Amount Paid",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹${totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: const Color(0xFF4CAF50),
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              Icons.close_rounded,
                              "Close",
                              const Color(0xFF6B7280),
                              () => Navigator.pop(context),
                              isSmallScreen,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: _actionButton(
                              Icons.share_rounded,
                              "Share",
                              const Color(0xFF3B82F6),
                              () => _shareReceipt(receipts),
                              isSmallScreen,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: _actionButton(
                              Icons.download_rounded,
                              "Download",
                              const Color(0xFF4CAF50),
                              () => _downloadReceipt(receipts),
                              isSmallScreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
        ),
         error: (err, _) => ErrorStatePage(error: err, onRetry: _loadData),
      ),
    );
  }

  Widget _buildDetail(String label, String value, bool isSmall) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: isSmall ? 12 : 13),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 1,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 12 : 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    bool isSmall,
  ) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: isSmall ? 10 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmall ? 16 : 18),
        SizedBox(height: isSmall ? 2 : 4),
        Text(label, style: TextStyle(fontSize: isSmall ? 10 : 11)),
      ],
    ),
  );
// Future<void> _shareReceipt(List<DueHistory> receipts) async {
//   try {
//     final pdf = pw.Document();
//     double totalAmount = receipts.isNotEmpty
//         ? (receipts[0].paidAmount ?? 0.0)
//         : 0.0;

//     pdf.addPage(
//       pw.Page(
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
              
//               // ✅ Title
//               pw.Center(
//                 child: pw.Text(
//                   "Receipt",
//                   style: pw.TextStyle(
//                     fontSize: 26,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),

//               pw.SizedBox(height: 20),

//               // ✅ Society Name
//               pw.Text(
//                 receipts[0].society_Name ?? "Society Name",
//                 style: pw.TextStyle(
//                   fontSize: 16,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),

//               // ✅ Registration No below society name
//               pw.Text(
//                 "Reg. No: ${receipts[0].registration_No ?? "-"}",
//                 style: pw.TextStyle(
//                   fontSize: 12,
//                   color: PdfColors.grey700,
//                 ),
//               ),

//               pw.SizedBox(height: 20),

//               // Paid bills message
//               pw.Text(
//                 "${receipts.length} ${receipts.length > 1 ? 'bills' : 'bill'} paid successfully",
//                 style: pw.TextStyle(fontSize: 12),
//               ),

//               pw.SizedBox(height: 30),

//               // Bills Paid Heading
//               pw.Text(
//                 "Bills Paid",
//                 style: pw.TextStyle(
//                   fontSize: 16,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),

//               pw.SizedBox(height: 10),

//               // Bills table
//               pw.Table.fromTextArray(
//                 headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 headers: ['Receipt No', 'Bill No', 'Amount', 'Status'],
//                 data: receipts.map((r) {
//                   return [
//                     r.billRef ?? "-",
//                     r.billno ?? "-",
//                     "₹${r.amount?.toStringAsFixed(2) ?? "0.00"}",
//                     "PAID",
//                   ];
//                 }).toList(),
//               ),

//               pw.SizedBox(height: 20),

//               // Payment Details Box
//               pw.Container(
//                 padding: pw.EdgeInsets.all(16),
//                 decoration: pw.BoxDecoration(
//                   border: pw.Border.all(color: PdfColors.grey300),
//                   borderRadius: pw.BorderRadius.circular(8),
//                 ),
//                 child: pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       "Payment Details",
//                       style: pw.TextStyle(
//                         fontSize: 16,
//                         fontWeight: pw.FontWeight.bold,
//                       ),
//                     ),

//                     pw.SizedBox(height: 12),

//                     _pdfRow("Name", receipts[0].name ?? "-"),
//                     _pdfRow("Flat No", receipts[0].unit ?? "-"),

//                     _pdfRow(
//                       "Date",
//                       receipts[0].date != null
//                           ? DateFormat('d MMM yyyy')
//                               .format(DateTime.parse(receipts[0].date!))
//                           : "-",
//                     ),

//                     _pdfRow("Payment Mode", receipts[0].payMode ?? "-"),

//                     pw.Divider(),

//                     pw.Row(
//                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                       children: [
//                         pw.Text(
//                           "Total Amount Paid",
//                           style: pw.TextStyle(
//                             fontSize: 14,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                         pw.Text(
//                           "₹${totalAmount.toStringAsFixed(2)}",
//                           style: pw.TextStyle(
//                             fontSize: 16,
//                             fontWeight: pw.FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     // Save file
//     final output = await getTemporaryDirectory();
//     final fileName =
//         "receipt_${receipts[0].billno}_${receipts.length}_bills.pdf";
//     final file = File("${output.path}/$fileName");
//     await file.writeAsBytes(await pdf.save());

//     // Share
//     await Share.shareXFiles([
//       XFile(file.path),
//     ], text: 'Payment Receipt - ₹${totalAmount.toStringAsFixed(2)}');

//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(ErrorMessageMapper.map(e)),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
// }

Future<void> _shareReceipt(List<DueHistory> receipts) async {
  try {
    final pdf = pw.Document();
    double totalAmount = receipts.isNotEmpty
        ? (receipts[0].paidAmount ?? 0.0)
        : 0.0;

    // Load font that supports Rupee symbol
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ✅ MODERN HEADER WITH ACCENT
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    // Receipt Title
                    pw.Text(
                      "PAYMENT RECEIPT",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        letterSpacing: 1.5,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    // Society Name
                    pw.Text(
                      receipts[0].society_Name ?? "Society Name",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    
                    // Registration Number
                    pw.Text(
                      "Reg. No: ${receipts[0].registration_No ?? "-"}",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                        font: ttf,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Success Message
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(20),
                    border: pw.Border.all(color: PdfColors.green300),
                  ),
                  child: pw.Text(
                    "${receipts.length} ${receipts.length > 1 ? 'bills' : 'bill'} paid successfully",
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.green900,
                      fontWeight: pw.FontWeight.bold,
                      font: ttfBold,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 24),

              // Bills Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table.fromTextArray(
                  border: null,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: ttfBold,
                  ),
                  cellStyle: pw.TextStyle(font: ttf),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue700,
                  ),
                  headerPadding: const pw.EdgeInsets.all(12),
                  cellPadding: const pw.EdgeInsets.all(10),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.center,
                  },
                  headers: ['Receipt No', 'Bill No', 'Amount', 'Status'],
                  data: receipts.map((r) {
                    return [
                      r.billRef ?? "-",
                      r.billno ?? "-",
                      "₹${r.amount?.toStringAsFixed(2) ?? "0.00"}",
                      "PAID",
                    ];
                  }).toList(),
                ),
              ),

              pw.SizedBox(height: 24),

              // Payment Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Payment Details",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _pdfRow("Name", receipts[0].name ?? "-", ttf, ttfBold),
                    _pdfRow("Flat No", receipts[0].unit ?? "-", ttf, ttfBold),
                    _pdfRow(
                      "Date",
                      receipts[0].date != null
                          ? DateFormat('d MMM yyyy')
                              .format(DateTime.parse(receipts[0].date!))
                          : "-",
                      ttf,
                      ttfBold,
                    ),
                    _pdfRow("Payment Mode", receipts[0].payMode ?? "-", ttf, ttfBold),
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfColors.grey400, thickness: 1.5),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue700,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Total Amount Paid",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: ttfBold,
                            ),
                          ),
                          pw.Text(
                            "₹${totalAmount.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: ttfBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  "Thank you for your payment",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                    font: ttf,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save file
    final output = await getTemporaryDirectory();
    final fileName =
        "receipt_${receipts[0].billno}_${receipts.length}_bills.pdf";
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());

    // Share
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Payment Receipt - ₹${totalAmount.toStringAsFixed(2)}');

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(e)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}


//   Future<void> _downloadReceipt(List<DueHistory> receipts) async {
//     try {
//       final pdf = pw.Document();
//       double totalAmount = receipts.isNotEmpty
//           ? (receipts[0].paidAmount ?? 0.0)
//           : 0.0;

//     pdf.addPage(
//   pw.Page(
//     build: (pw.Context context) {
//       return pw.Column(
//         crossAxisAlignment: pw.CrossAxisAlignment.start,
//         children: [

//           // ❌ SUCCESS ICON SECTION REMOVED

//           // ✅ NEW SIMPLE TITLE
//           pw.Center(
//             child: pw.Text(
//               "Receipt",
//               style: pw.TextStyle(
//                 fontSize: 26,
//                 fontWeight: pw.FontWeight.bold,
//               ),
//             ),
//           ),

//           pw.SizedBox(height: 20),

//           // ✅ SOCIETY NAME (TOP)
//           pw.Text(
//             receipts[0].society_Name ?? "Society Name",
//             textAlign:pw.TextAlign.center ,
//             style: pw.TextStyle(
//               fontSize: 16,
//               fontWeight: pw.FontWeight.bold,
//             ),
//           ),

//           // ✅ REGISTRATION NUMBER (BELOW)
//           pw.Text(
//             "Reg. No: ${receipts[0].registration_No ?? "-"}",
//             textAlign:pw.TextAlign.center ,
//             style: pw.TextStyle(
//               fontSize: 12,
//               color: PdfColors.grey700,
//             ),
//           ),

//           pw.SizedBox(height: 20),
//  pw.Text(
//   textAlign:pw.TextAlign.center ,
//                 "${receipts.length} ${receipts.length > 1 ? 'bills' : 'bill'} paid successfully",
//                 style: pw.TextStyle(fontSize: 12),
//               ),

//                 pw.SizedBox(height: 10),
//                 pw.Table.fromTextArray(
//                   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                   headers: ['Receipt No', 'Bill No', 'Amount', 'Status'],
//                   data: receipts.map((r) {
//                     return [
//                       r.billRef ?? "-",
//                       r.billno ?? "-",
//                       "₹${r.amount?.toStringAsFixed(2) ?? "0.00"}",
//                       "PAID",
//                     ];
//                   }).toList(),
//                 ),
//                 pw.SizedBox(height: 20),
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(16),
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey300),
//                     borderRadius: pw.BorderRadius.circular(8),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text(
//                         "Payment Details",
//                         style: pw.TextStyle(
//                           fontSize: 16,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.SizedBox(height: 12),
//                       _pdfRow("Name", receipts[0].name ?? "-"),
//                       _pdfRow("Flat No", receipts[0].unit ?? "-"),
//                       _pdfRow(
//                         "Date",
//                         receipts[0].date != null
//                             ? DateFormat(
//                                 'd MMM yyyy',
//                               ).format(DateTime.parse(receipts[0].date!))
//                             : "-",
//                       ),
//                       _pdfRow("Payment Mode", receipts[0].payMode ?? "-"),
//                       pw.Divider(),
//                       pw.Row(
//                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                         children: [
//                           pw.Text(
//                             "Total Amount Paid",
//                             style: pw.TextStyle(
//                               fontSize: 14,
//                               fontWeight: pw.FontWeight.bold,
//                             ),
//                           ),
//                           pw.Text(
//                             "₹${totalAmount.toStringAsFixed(2)}",
//                             style: pw.TextStyle(
//                               fontSize: 16,
//                               fontWeight: pw.FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       );

//       String? downloadsPath;
//       if (Platform.isAndroid) {
//         downloadsPath = '/storage/emulated/0/Download';
//       } else if (Platform.isIOS) {
//         final directory = await getApplicationDocumentsDirectory();
//         downloadsPath = directory.path;
//       }

//       if (downloadsPath != null) {
//         final fileName =
//             "receipt_${receipts[0].billno}_${receipts.length}_bills.pdf";
//         final file = File("$downloadsPath/$fileName");
//         await file.writeAsBytes(await pdf.save());

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 "Receipt downloaded to Downloads folder: $fileName",
//               ),
//               backgroundColor: const Color(0xFF4CAF50),
//               behavior: SnackBarBehavior.floating,
//               action: SnackBarAction(
//                 label: 'Open',
//                 textColor: Colors.white,
//                 onPressed: () => OpenFile.open(file.path),
//               ),
//             ),
//           );
//         }
//         await OpenFile.open(file.path);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(ErrorMessageMapper.map(e)),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   pw.Widget _pdfRow(String label, String value) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 4),
//       child: pw.Row(
//         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//         children: [
//           pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
//           pw.Text(
//             value,
//             style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
Future<void> _downloadReceipt(List<DueHistory> receipts) async {
  try {
    final pdf = pw.Document();
    double totalAmount = receipts.isNotEmpty
        ? (receipts[0].paidAmount ?? 0.0)
        : 0.0;

    // Load font that supports Rupee symbol
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ✅ MODERN HEADER WITH ACCENT
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    // Receipt Title
                    pw.Text(
                      "PAYMENT RECEIPT",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        letterSpacing: 1.5,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    
                    // Society Name
                    pw.Text(
                      receipts[0].society_Name ?? "Society Name",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    
                    // Registration Number
                    pw.Text(
                      "Reg. No: ${receipts[0].registration_No ?? "-"}",
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                        font: ttf,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Success Message
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(20),
                    border: pw.Border.all(color: PdfColors.green300),
                  ),
                  child: pw.Text(
                    "${receipts.length} ${receipts.length > 1 ? 'bills' : 'bill'} paid successfully",
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.green900,
                      fontWeight: pw.FontWeight.bold,
                      font: ttfBold,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 24),

              // Bills Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table.fromTextArray(
                  border: null,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    font: ttfBold,
                  ),
                  cellStyle: pw.TextStyle(font: ttf),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue700,
                  ),
                  headerPadding: const pw.EdgeInsets.all(12),
                  cellPadding: const pw.EdgeInsets.all(10),
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.center,
                  },
                  headers: ['Receipt No', 'Bill No', 'Amount', 'Status'],
                  data: receipts.map((r) {
                    return [
                      r.billRef ?? "-",
                      r.billno ?? "-",
                      "₹${r.amount?.toStringAsFixed(2) ?? "0.00"}",
                      "PAID",
                    ];
                  }).toList(),
                ),
              ),

              pw.SizedBox(height: 24),

              // Payment Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Payment Details",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                        font: ttfBold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _pdfRow("Name", receipts[0].name ?? "-", ttf, ttfBold),
                    _pdfRow("Flat No", receipts[0].unit ?? "-", ttf, ttfBold),
                    _pdfRow(
                      "Date",
                      receipts[0].date != null
                          ? DateFormat('d MMM yyyy')
                              .format(DateTime.parse(receipts[0].date!))
                          : "-",
                      ttf,
                      ttfBold,
                    ),
                    _pdfRow("Payment Mode", receipts[0].payMode ?? "-", ttf, ttfBold),
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfColors.grey400, thickness: 1.5),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue700,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            "Total Amount Paid",
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: ttfBold,
                            ),
                          ),
                          pw.Text(
                            "₹${totalAmount.toStringAsFixed(2)}",
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              font: ttfBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  "Thank you for your payment",
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                    font: ttf,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final fileName =
        "receipt_${receipts[0].billno}_${receipts.length}_bills.pdf";
    final file = File("${directory.path}/$fileName");
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Receipt downloaded: $fileName"),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    }
    await OpenFile.open(file.path);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(e)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

pw.Widget _pdfRow(String label, String value, pw.Font ttf, pw.Font ttfBold) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
            font: ttf,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
            font: ttfBold,
          ),
        ),
      ],
    ),
  );
}
}
