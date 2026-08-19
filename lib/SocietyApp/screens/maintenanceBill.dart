import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';
import 'package:flutter_html/flutter_html.dart';

class Charge {
  final String name;
  final double amount;

  Charge({required this.name, required this.amount});
}

class PrintMaintenanceBill extends ConsumerStatefulWidget {
  final int maintenanceId;
  final int? notifyStatusId;
  const PrintMaintenanceBill({
    super.key,
    required this.maintenanceId,
    this.notifyStatusId,
  });

  @override
  ConsumerState<PrintMaintenanceBill> createState() =>
      _PrintMaintenanceBillState();
}

class _PrintMaintenanceBillState extends ConsumerState<PrintMaintenanceBill> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final info = ref.read(basicInfoViewModelProvider);
      final flatId = info.flatId ?? 0;
      final society = info.societyID ?? "<no-society>";
      final ownerId = info.ownerId ?? 0;

      if (flatId > 0 && widget.maintenanceId > 0) {
        if (widget.notifyStatusId != null && widget.notifyStatusId! > 0) {
          // call update and capture result
          final updated = await ref
              .read(broadcastViewModelProvider.notifier)
              .updateNotificationStatus(
                widget.notifyStatusId!,
                society,
                ownerId,
              );
          await ref
              .read(broadcastViewModelProvider.notifier)
              .getNotification(society, ownerId);
          ref
              .read(dueHistoryViewModelProvider.notifier)
              .loadDueHistory(
                ref.watch(basicInfoViewModelProvider).flatId ?? 0,
              );
        } else {
          print(">>> skipping update: notifyStatusId is null or zero");
        }
        await ref
            .read(maintenanceViewModelProvider.notifier)
            .getMaintenanceList(flatId, widget.maintenanceId);
      } else {
        print("Invalid flatId or maintenanceId");
      }
    } catch (e, st) {
      print("Error in _loadData: $e\n$st");
    }
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(maintenanceViewModelProvider);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    double font(double px) => (w / 400) * px;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 239, 241, 248),
        title: const Text(
          "Maintenance Bill",
          style: TextStyle(color: Colors.black),
        ),
      ),

      body: billState.maintenanceList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // error: (e, st) => Center(child: Text("Error: $e")),
        error: (err, _) =>
            ErrorStatePage(error: err, onRetry: _loadData),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(child: Text("No Maintenance Bill Found"));
          }

          final bill = bills.first; // Displaying first bill only
          final chargesList = bill.charges.entries.toList();
          // print("Bill: ${bills.first.toJson()}");
          // If interest exists, append it to the charges list so it appears in the charges table
          final double interestAmt = bill.taxInterestAmt ?? 0.0;
          if (interestAmt != 0.0) {
            chargesList.add(MapEntry("Late Payment Interest", interestAmt));
          }
          return SafeArea(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(w * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(w * 0.02),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          // Text(
                          //   bill.societyName ?? "Society Name",
                          //   style: TextStyle(
                          //     fontSize: font(18),
                          //     fontWeight: FontWeight.bold,
                          //     color: Colors.black,
                          //   ),
                          // ),
                          Center(
                            child: Text(
                              bill.societyName ?? "Society Name",
                              textAlign:
                                  TextAlign.center, // ← centers long text
                              style: TextStyle(
                                fontSize: font(18),
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          Text(
                            bill.registrationNo ?? "Registration No",
                            style: TextStyle(
                              fontSize: font(14),
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            bill.address1 ?? "N/A",
                            style: TextStyle(
                              fontSize: font(14),
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: h * 0.005),
                          Text(
                            "Maintenance Bill",
                            style: TextStyle(
                              fontSize: font(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const Divider(color: Colors.black),
                        ],
                      ),
                    ),
                    SizedBox(height: h * 0.015),

                    // Owner & Bill No
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Name: ${bill.ownerName}",
                          style: TextStyle(fontSize: font(14)),
                        ),
                        Text(
                          "Bill No: ${bill.billNo}",
                          style: TextStyle(fontSize: font(14)),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.015),

                    // Flat & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Flat No: ${bill.flatNo}",
                          style: TextStyle(fontSize: font(14)),
                        ),
                        Text(
                          "Bill Date: ${_formatDate(bill.genDate)}",
                          style: TextStyle(fontSize: font(14)),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.015),

                    // Area & Due Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Area: ${bill.sqFt} Sq.Ft",
                          style: TextStyle(fontSize: font(14)),
                        ),
                        Text(
                          "Due Date: ${_formatDate(bill.dueDate)}",
                          style: TextStyle(fontSize: font(14)),
                        ),
                      ],
                    ),
                    SizedBox(height: h * 0.015),

                    // Text(
                    //   "Bill Period: ${_formatDate(bill.dueDate)} ",
                    //   style: TextStyle(fontSize: font(14)),
                    // ),
                    // const Divider(color: Colors.black, thickness: 1),

                    // Charges Table Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sr.No",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: font(14),
                          ),
                        ),
                        SizedBox(width: w * 0.10),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Nature of Charges",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: font(14),
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // optional: avoids overflow
                            ),
                          ),
                        ),
                        Text(
                          "Amount (Rs)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: font(14),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.black),

                    // Convert Map<String, double> into a list for iteration
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: chargesList.length,
                      itemBuilder: (context, index) {
                        final entry = chargesList[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: h * 0.005),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${index + 1}",
                                style: TextStyle(fontSize: font(14)),
                              ),
                              SizedBox(width: w * 0.17),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    entry.key.toString(),
                                    style: TextStyle(fontSize: font(14)),
                                    overflow: TextOverflow
                                        .ellipsis, // optional: avoids overflow
                                  ),
                                ),
                              ),
                              Text(
                                entry.value.toStringAsFixed(2),
                                style: TextStyle(fontSize: font(14)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Divider(color: Colors.black),

                    // Totals
                    Builder(
                      builder: (context) {
                        final currentBillTotal = chargesList.fold(
                          0.0,
                          (sum, item) => sum + item.value,
                        );
                        final billDue = double.tryParse(bill.due ?? "0") ?? 0;
                        final isPartiallyPaid =
                            bill.billStatus?.toLowerCase() ==
                            "partially paid";
                        final payableForThisBill = isPartiallyPaid
                            ? billDue
                            : currentBillTotal;
                        final dueAsOf = billDue != 0
                            ? (bill.amtForward ?? 0.0)
                            : 0.0;
                        final grandTotal = payableForThisBill + dueAsOf;

                        return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _totalRow(
                          "Current Bill Total",
                          "₹${currentBillTotal.toStringAsFixed(2)}",
                          font,
                        ),
                        if (isPartiallyPaid)
                          _totalRow(
                            "Remaining Due",
                            "₹${billDue.toStringAsFixed(2)}",
                            font,
                          ),
                        if (bill.amtForward != 0.0 && billDue != 0)
                          _totalRow(
                            "Dues As Of(${_formatDate(bill.genDate)})",
                            "₹${bill.amtForward?.toStringAsFixed(2) ?? "0.00"}",
                            font,
                          ),

                        const Divider(color: Colors.black),
                        if (bill.advance != 0.0)
                          _totalRow(
                            "Adjusted Advance",
                            "₹${bill.advance?.toStringAsFixed(2) ?? "0.00"}",
                            font,
                          ),
                        _totalRow(
                          "Grand Total ",
                          "₹${grandTotal.toStringAsFixed(2)}",
                          font,
                          bold: true,
                        ),
                        const Divider(color: Colors.black, thickness: 2),
                        Text(
                          "Amount in Text: ${convertAmountToWords(grandTotal)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: font(14),
                          ),
                        ),
                        const Divider(color: Colors.black),
                      ],
                    );
                      },
                    ),

                    // Terms & Conditions (HTML safe)
                    Html(
                      data: bill.terms ?? '',
                      style: {"body": Style(fontSize: FontSize(13))},
                    ),
                    SizedBox(height: h * 0.03),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "For: ${bill.societyName}",
                            style: TextStyle(fontSize: font(14)),
                          ),
                          SizedBox(height: h * 0.01),
                          const Text(
                            "HON-SECRETARY",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String convertAmountToWords(double amount) {
    final units = [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen",
    ];

    final tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety",
    ];

    String twoDigitsToWords(int n) {
      if (n == 0) return "";
      if (n < 20) return units[n];
      return tens[n ~/ 10] + (n % 10 != 0 ? " ${units[n % 10]}" : "");
    }

    String threeDigitsToWords(int n) {
      if (n == 0) return "";
      if (n < 100) return twoDigitsToWords(n);
      return "${units[n ~/ 100]} Hundred${n % 100 != 0 ? " ${twoDigitsToWords(n % 100)}" : ""}";
    }

    String numberToWords(int number) {
      if (number == 0) return "Zero";
      String result = "";
      int crore = (number ~/ 10000000);
      int lakh = (number ~/ 100000) % 100;
      int thousand = (number ~/ 1000) % 100;
      int remainder = number % 1000;

      if (crore > 0) result += "${threeDigitsToWords(crore)} Crore ";
      if (lakh > 0) result += "${threeDigitsToWords(lakh)} Lakh ";
      if (thousand > 0) result += "${threeDigitsToWords(thousand)} Thousand ";
      if (remainder > 0) result += "${threeDigitsToWords(remainder)} ";

      return result.trim();
    }

    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();

    String rupeesPart = numberToWords(rupees);
    String paisePart = paise > 0 ? "${numberToWords(paise)} Paise" : "";

    if (paisePart.isNotEmpty) {
      return "$rupeesPart Rupees and $paisePart Only";
    } else {
      return "$rupeesPart Rupees Only";
    }
  }

  // 🔹 Utility
  String _formatDate(String? rawDate) {
    if (rawDate == null) return "N/A";
    try {
      final d = DateTime.parse(rawDate);
      return "${d.day}-${d.month}-${d.year}";
    } catch (_) {
      return rawDate;
    }
  }

  Widget _totalRow(
    String label,
    String value,
    double Function(double) font, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: font(14),
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: font(14),
            fontWeight: bold ? FontWeight.bold : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
