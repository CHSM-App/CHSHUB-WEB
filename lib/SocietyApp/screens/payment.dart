import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:society_app/SocietyApp/screens/demo.dart';
import 'package:society_app/SocietyApp/screens/errorstate.dart';
import 'package:society_app/SocietyApp/screens/maintenancebill.dart';
import 'package:society_app/SocietyApp/screens/receipt.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/broadcast.dart';
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/domain/models/receipt.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int? notifyStatusId;
  const PaymentScreen({super.key, this.notifyStatusId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentScreen>
    with TickerProviderStateMixin {
  final Set<DueHistory> _selectedBills = {};
  double _totalAmount = 0;
  String _currentView = "INVOICE";

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String _selectedMode = "UPI";
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  double _editableAmount = 0.0;
  double _minimumAmount = 0.0;
  double _billType2Note = 0.0;
  bool _isAmountEditable = false;
  // late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers (same as DirectoryScreen)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // _razorpay = Razorpay();
    // _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    // _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    // _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final info = ref.read(basicInfoViewModelProvider);
    if (widget.notifyStatusId != null && widget.notifyStatusId! > 0) {
      ref
          .read(broadcastViewModelProvider.notifier)
          .updateNotificationStatus(
            widget.notifyStatusId!,
            info.societyID ?? "",
            info.ownerId ?? 0,
          );
    } else {
      // Opened via Home's Payment quick-access card (no specific
      // notification tapped) -- clear every unseen Maintenance notification
      // so the Home badge reflects that the user has now seen this screen.
      ref
          .read(broadcastViewModelProvider.notifier)
          .markAllNotificationsSeenByType(
            info.societyID ?? "",
            info.ownerId ?? 0,
            "Maintenance",
          );
    }
  }

  void _loadData() {
    // Reset and start animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();

    // Load payment data
    ref
        .read(dueHistoryViewModelProvider.notifier)
        .loadDueHistory(ref.watch(basicInfoViewModelProvider).flatId ?? 0);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Wallet Selected: ${response.walletName}")),
    );
  }

  @override
  void dispose() {
    // _razorpay.clear();
    _fadeController.dispose();
    _slideController.dispose();
    _paymentController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _toggleSelection(DueHistory item) {
    setState(() {
      if (_selectedBills.contains(item)) {
        _selectedBills.remove(item);
      } else {
        _selectedBills.add(item);
      }
      _calculatePaymentDetails();
    });
  }

  bool _isSelected(DueHistory item) {
    return _selectedBills.contains(item);
  }

  void _switchView(String view) {
    setState(() {
      _currentView = view;
      _selectedBills.clear();
      _totalAmount = 0.0;
      _editableAmount = 0.0;
      _minimumAmount = 0.0;
      _billType2Note = 0.0;
      _isAmountEditable = false;
    });

    // Restart animations when switching views
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _calculatePaymentDetails() {
    double billType1Total = 0.0;
    double billType0Total = 0.0;
    double billType2Total = 0.0;

    bool hasBillType0 = false;
    bool hasBillType1 = false;

    for (var bill in _selectedBills) {
      if (bill.billType == 1) {
        billType1Total += bill.due ?? 0;
        hasBillType1 = true;
      } else if (bill.billType == 0) {
        billType0Total += bill.due ?? 0;
        hasBillType0 = true;
      } else if (bill.billType == 2) {
        billType2Total += bill.due ?? 0;
      }
    }

    _billType2Note = billType2Total;

    if (hasBillType1 && !hasBillType0) {
      _isAmountEditable = false;
      _editableAmount = billType1Total;
      _minimumAmount = billType1Total;
    } else if (hasBillType0 && !hasBillType1) {
      _isAmountEditable = true;
      _editableAmount = billType0Total;
      _minimumAmount = 0.0;
    } else if (hasBillType0 && hasBillType1) {
      _isAmountEditable = true;
      _editableAmount = billType0Total + billType1Total;
      _minimumAmount = billType1Total;
    } else {
      _isAmountEditable = false;
      _editableAmount = 0.0;
      _minimumAmount = 0.0;
    }

    _paymentController.text = _editableAmount.toStringAsFixed(2);
    _totalAmount = _editableAmount;
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(dueHistoryViewModelProvider).dueHistory;
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: paymentsState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              ErrorStatePage(error: err, onRetry: _loadData),
          data: (payments) {
            final invoicePayments = payments
                .where(
                  (e) =>
                      e.pay_Mode_Name != "Receipt" &&
                      e.type?.toUpperCase() != "PAID",
                )
                .toList();
            final historyPayments = payments
                .where(
                  (e) =>
                      e.pay_Mode_Name == "Receipt" ||
                      e.type?.toUpperCase() == "PAID",
                )
                .toList();

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _switchView("INVOICE"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _currentView == "INVOICE"
                                          ? Colors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "Invoice",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _currentView == "INVOICE"
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _switchView("HISTORY"),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _currentView == "HISTORY"
                                          ? Colors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "History",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _currentView == "HISTORY"
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Expanded(
                        //   child: _currentView == "INVOICE"
                        //       ? _buildPaymentList(
                        //           invoicePayments,
                        //           selectable: true,
                        //         )
                        //       : _buildPaymentList(historyPayments),
                        // ),
                        Expanded(
                          child: _currentView == "INVOICE"
                              ? _buildPaymentList(
                                  invoicePayments,
                                  selectable: true,
                                )
                              : _buildPaymentList(historyPayments),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildPaymentBottom(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentBottom() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _selectedBills.isEmpty ? 0 : null,
      child: _selectedBills.isEmpty
          ? const SizedBox.shrink()
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmallScreen = constraints.maxWidth < 400;

                    if (isSmallScreen) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAmountSection(isSmallScreen: true),
                          if (_billType2Note > 0) ...[
                            const SizedBox(height: 8),
                            _buildBillType2Note(),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildPayButton(),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildAmountSection(
                                    isSmallScreen: false,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                _buildPayButton(),
                              ],
                            ),
                          ),
                          if (_billType2Note > 0) ...[
                            const SizedBox(height: 8),
                            _buildBillType2Note(),
                          ],
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildAmountSection({required bool isSmallScreen}) {
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isAmountEditable ? 'Payment Amount' : 'Total Amount',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isAmountEditable)
                Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
            ],
          ),
          const SizedBox(height: 8),
          if (_isAmountEditable)
            _buildEditableAmount()
          else
            Text(
              '₹${_editableAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.blue.shade800,
                letterSpacing: -0.5,
              ),
            ),
          if (_minimumAmount > 0 && _isAmountEditable)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Minimum: ₹${_minimumAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isAmountEditable ? 'Payment Amount' : 'Total Amount',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isAmountEditable)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isAmountEditable)
            _buildEditableAmount()
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₹${_editableAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue.shade800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          if (_minimumAmount > 0 && _isAmountEditable)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Note: bills must be fully paid (Minimum: ₹${_minimumAmount.toStringAsFixed(2)})',
                style: TextStyle(
                  fontSize: 12,
                  color: const Color.fromARGB(255, 186, 51, 27),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _buildEditableAmount() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      child: TextField(
        controller: _paymentController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.blue.shade800,
          letterSpacing: -0.5,
        ),
        decoration: InputDecoration(
          prefix: Text(
            '₹',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.blue.shade800,
            ),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _editableAmount = double.tryParse(value) ?? 0.0;
          });
        },
      ),
    );
  }

  Widget _buildBillType2Note() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Note: Additional ₹${_billType2Note.toStringAsFixed(0)} (bill_type 2)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_editableAmount <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Please enter a valid amount greater than ₹0',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
          if (_minimumAmount > 0 && _editableAmount < _minimumAmount) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Minimum payment of ₹${_minimumAmount.toStringAsFixed(0)} is required',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }

          _submitPayment(_editableAmount);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Pay Now',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(
    List<DueHistory> payments, {
    bool selectable = false,
  }) {
    if (payments.isEmpty) {
      return const Center(child: Text("No payments found"));
    }

    // Calculate dynamic bottom padding based on selection
    double bottomPadding = _selectedBills.isEmpty ? 16 : 200;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = payments[index];
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 800 + (index * 100)),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: GestureDetector(
                    onTap: selectable ? () => _toggleSelection(item) : null,
                    child: _buildPaymentCard(
                      item,
                      isSelected: _isSelected(item),
                      isHistoryTab: !selectable,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String getStatus(DueHistory item) {
    if (item.type?.toLowerCase() == "pending") return "PENDING";
    if (item.type?.toLowerCase() == 'paid') return "PAID";
    if (item.type?.toLowerCase() == "partially paid") return "PARTIALLY PAID";
    return "N/A";
  }

  Widget _buildPaymentCard(
    DueHistory item, {
    bool isSelected = false,
    required bool isHistoryTab, // true = history tab, false = invoice tab
  }) {
    final status = getStatus(item);
    final statusColor =
        {
          "PAID": Colors.green,
          "PARTIALLY PAID": Colors.orange,
          "PENDING": Colors.red,
        }[status] ??
        Colors.grey;

    final bool isReceipt = item.pay_Mode_Name == "Receipt";
    final cardColor = isReceipt ? Colors.green : Colors.orange;

    final Color borderColor = isSelected
        ? (isReceipt ? Colors.green.shade400 : Colors.blue.shade400)
        : Colors.grey.shade300;

    // ---------------- AMOUNT LOGIC ----------------
    double amount;
    if (isHistoryTab) {
      // History tab → total amount actually paid (principal + interest for paid invoices)
      amount = isReceipt
          ? (item.total_Amount ?? 0)
          : (item.total_Amount ?? 0) + (item.taxInterestAmt ?? 0);
    } else {
      // Invoice tab → due amount (pending invoice)
      amount = item.due ?? 0;
    }

    String amountToShow = amount.toStringAsFixed(2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- TOP ----------
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isReceipt ? Icons.receipt_long : Icons.description,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),

                // TEXTS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReceipt ? "RECEIPT" : "INVOICE",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatToReadableDate(item.date),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // AMOUNT
                    Text(
                      "₹$amountToShow",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ],
                ),

                const Spacer(),
                // 🔴 NEW TAG only for:
                // - Invoice tab (isHistoryTab == false)
                // - Invoice item (!isReceipt)
                // - Unseen (seenStatus == 0)
                if (!isHistoryTab && !isReceipt && (item.seenStatus == 0))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "NEW",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.type?.toLowerCase() == "pending"
                        ? cardColor
                        : statusColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isReceipt ? status : "BILL $status",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // ---------- FOOTER ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  isReceipt ? "Payment On" : "Due On",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
                const SizedBox(width: 4),
                Text(
                  isReceipt
                      ? _formatToReadableDate(item.date)
                      : _formatToReadableDate(item.due_Date),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (isReceipt) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentSuccessPage(
                            receiptId: item.receipt_Id ?? 0,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrintMaintenanceBill(
                            maintenanceId: item.billId ?? 0,
                            notifyStatusId: item.notifyStatusId ?? 0,
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isReceipt ? Icons.receipt_long : Icons.description,
                    color: cardColor,
                    size: 16,
                  ),
                  label: Text(
                    isReceipt ? "Receipt" : "Invoice",
                    style: TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    backgroundColor: cardColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatToReadableDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return rawDate;
    }
  }

  String _formatDate(String dateString) {
    final dateTime = DateTime.tryParse(dateString) ?? DateTime.now();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  String getMonthNameFromString(String dateString) {
    DateTime date = DateTime.parse(dateString);
    return "${DateFormat.MMMM().format(date)} Maintenance";
  }

  Future<void> _submitPayment(double amount) async {
    final result = await PaymentService.startPayment(context, ref, amount);
    if (result["success"] == false) {
      debugPrint("❌ Payment Failed");
      return;
    } else {
      debugPrint(result.toString());
      try {
        final basicInfo = ref.read(basicInfoViewModelProvider);
        final societyId = basicInfo.societyID ?? "";
        final flatId = ref.read(basicInfoViewModelProvider).flatId ?? 0;
        final ownerId = basicInfo.ownerId ?? 0;
        final unit = basicInfo.unit ?? "";

        if (societyId.isEmpty) {
          throw Exception("Invalid society ID");
        }

        final billType1Ids = _selectedBills
            .where((b) => b.billType == 1)
            .map((b) => b.bill_No)
            .toList();

        final billType0Ids = _selectedBills
            .where((b) => b.billType == 0)
            .map((b) => b.bill_No)
            .toList();

        final combinedBillIds = [...billType1Ids, ...billType0Ids].join(',');

        final receipt = Receipt(
          societyId: societyId,
          flatId: flatId,
          payMode: result["method"].toString(),
          chequeNo: "",
          chequeDate: null,
          bankName: result["bank"]?.toString() ?? "",
          transactionRef: result["rrn"]?.toString() == ""
              ? result["payment_id"]?.toString()
              : result["rrn"]?.toString(),
          billDetails: combinedBillIds,
          paidAmount: amount,
          remarks: "Paid via ${result["method"].toString()}",
          status: 3,
          createdBy: ownerId,
        );
        final receiptId = await ref
            .read(dueHistoryViewModelProvider.notifier)
            .addReceipt(receipt);

        if (receiptId == null) {
          throw Exception("Receipt ID is null after saving payment");
        }
        // await ref
        //     .read(dueHistoryViewModelProvider.notifier)
        //     .addReceipt(receipt);
        // final paymentState = ref.read(dueHistoryViewModelProvider);

        // final receiptId = paymentState.data?['receipt_id'];

        _selectedBills.clear();

        await ref
            .read(directoryViewModelProvider.notifier)
            .loadAllTokens(societyId);

        final tokenState = ref.watch(directoryViewModelProvider);
        late List<String> tokenList;

        tokenState.allTokens.when(
          data: (tokens) async {
            tokenList = tokens.map((e) => e.webToken ?? '').toList();

            for (var token in tokens) {
              final broadcast = Broadcast(
                societyId: societyId,
                title: "New Payment Received",
                body: "Payment has been made by Unit: $unit",
                userType: "Member",
                userId: token.userId,
                notificationType: "Payment",
                seenStatus: 0,
                notificationId: receiptId,
                ownerId: ownerId,
              );

              await ref
                  .read(broadcastViewModelProvider.notifier)
                  .insertNotification(broadcast);
            }

            final notification = SendNotification(
              tokens: tokenList,
              title: "New Payment Received",
              body: "Payment has been made by Unit: $unit",
            );

            await ref
                .read(alertViewModelProvider.notifier)
                .sendNotification(notification);
          },
          loading: () => debugPrint('Loading tokens...'),
          error: (err, _) => debugPrint('Error loading tokens: $err'),
        );

        ref.read(dueHistoryViewModelProvider.notifier).loadDueHistory(flatId);
      } catch (e, stack) {
        debugPrint("❌ Exception in _submitPayment: $e\n$stack");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ErrorMessageMapper.map(e)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
