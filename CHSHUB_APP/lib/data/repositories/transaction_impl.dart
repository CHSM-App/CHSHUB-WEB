import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/test_payment.dart';
import 'package:society_app/domain/repository/transaction_repository.dart';


class TransactionImpl implements TransactionRepository {
  final ApiService apiService;

  TransactionImpl(this.apiService);
@override
  Future<double> getTransaction(int flatId) async {
  final res = await apiService.getTransaction(flatId);
  if (res is List && res.isNotEmpty && res.first['balance'] != null) {
    return (res.first['balance'] as num).toDouble();
  }
  return 0.0;
}
  @override
  Future createPaymentOrder(TestPayment payment) {
   return apiService.createPaymentOrder(payment);
  }
  
  @override
  Future verifyPayment(TestPayment payment) {
    return apiService.verifyPayment(payment);
  }
  
}
