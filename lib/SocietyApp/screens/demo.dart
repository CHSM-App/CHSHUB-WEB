import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/domain/models/test_payment.dart';
import 'package:society_app/presentation/providers/viewmodel_provider.dart';

class PaymentService {
  static final Razorpay _razorpay = Razorpay();

  static  Future<Map<String, dynamic>> startPayment(
    BuildContext context,
    WidgetRef ref,
    double amount

  ) async {
    final completer = Completer<Map<String, dynamic>>();

    try {
      // ✅ Listen to Razorpay events
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        debugPrint("✅ Payment Success: ${response.paymentId}");
        final verified = await _verifyPayment(context, ref, response);
        completer.complete(verified);
      });

      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        debugPrint("❌ Payment failed: ${response.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed"), backgroundColor: Colors.red),
        );
        if (!completer.isCompleted) completer.complete({"success": false});
        _razorpay.clear();
      });

      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        debugPrint("External wallet selected: ${response.walletName}");
      });

      // ✅ 1. Create Razorpay order from backend
      final payment = TestPayment(
        amount: (amount * 100).toDouble(), // paise
        currency: "INR",
        receipt: 'order_rcptid_${DateTime.now().millisecondsSinceEpoch}',
      );

      await ref.read(TransactionViewModelProvider.notifier).createPaymentOrder(payment);
      final paymentState = ref.read(TransactionViewModelProvider);
      final mobile=  ref.read(basicInfoViewModelProvider).mobile ?? "9999999999";
      final email=  ref.read(basicInfoViewModelProvider).email ?? "user@gmail.com";
      if (paymentState.data != null && paymentState.data!['id'] != null) {
        final orderId = paymentState.data!['id'];
        debugPrint("✅ Order created successfully: $orderId");

        // ✅ 2. Open Razorpay checkout
        var options = {
          'key': 'rzp_test_Rc0pHtivtmZFk6',
          
          'amount': (amount * 100).toDouble(),
          'name': 'CHSHUB',
          'description': 'Bill Payment', 
          'order_id': orderId,
          'prefill': {'contact':  mobile, 'email': email},
          'theme': {'color': '#0A8ED9'},
        };

        _razorpay.open(options); 
      } else {
        debugPrint("❌ Failed to create order: ${paymentState.error}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Something Went Wrong! Please try again"), backgroundColor: Colors.red),
        );
        completer.complete({"success": false});
      }
    } catch (e) {
      debugPrint("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessageMapper.map(e)),
          backgroundColor: Colors.red,
        ),
      );
      if (!completer.isCompleted) completer.complete({"success": false});
    }

    return completer.future;
  }

  static  Future<Map<String, dynamic>> _verifyPayment(
    BuildContext context,
    WidgetRef ref,
    PaymentSuccessResponse response,
  ) async {
    final payment = TestPayment(
      razorpayOrderId: response.orderId,
      razorpayPaymentId: response.paymentId,
      razorpaySignature: response.signature,
    );

    await ref.read(TransactionViewModelProvider.notifier).verifyPayment(payment);
    final state = ref.read(TransactionViewModelProvider);

    if (state.data?['success'] == true) {
      debugPrint("✅ Payment verified successfully");
      _razorpay.clear();
      return  { "success": true,
       "payment_id": state.data?["payment_id"],
      "order_id":state.data?["order_id"],
      "rrn": state.data?["rrn"],
      "method": state.data?["method"],
      "bank": state.data?["bank"],
      };
    } else {
      debugPrint("❌ Payment verification failed: ${state.error}");
      _razorpay.clear();
      return  { "success": false};
    }
  }

  static void dispose() {
    _razorpay.clear();
  }
}
