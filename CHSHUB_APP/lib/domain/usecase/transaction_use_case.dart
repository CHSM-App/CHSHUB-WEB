import 'package:society_app/domain/models/test_payment.dart';
import 'package:society_app/domain/repository/transaction_repository.dart';

class TransactionUseCase {
  final TransactionRepository repository;

  TransactionUseCase(this.repository);
  Future<double> getTransaction(int flatId ){
    return repository.getTransaction(flatId);
  }
  Future<dynamic> createPaymentOrder(TestPayment payment){
    return repository.createPaymentOrder(payment);
  }
   Future<dynamic> verifyPayment(TestPayment payment){
    return repository.verifyPayment(payment);
  }
}