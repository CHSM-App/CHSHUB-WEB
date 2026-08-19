
import 'package:society_app/domain/models/test_payment.dart';

abstract class TransactionRepository {
  Future<double> getTransaction(int flatId, );
   Future<dynamic> createPaymentOrder(TestPayment payment);
    Future<dynamic> verifyPayment(TestPayment payment);
}