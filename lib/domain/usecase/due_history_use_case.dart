
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/domain/models/receipt.dart';
import 'package:society_app/domain/repository/due_History_repository.dart';

class DueHistoryUseCase {
  DueHistoryRepository repository;

  DueHistoryUseCase(this.repository);

  Future<List<DueHistory>> getDueHistory(int ownerId, ) async {
    return await repository.getDueHistory(ownerId);
  }

  Future<List<DueHistory>> getReceipt(int receiptId, ) async {
    return await repository.getReceipt(receiptId);
  }
    Future<dynamic> addReceipt(Receipt receipt) {
    return repository.addReceipt(receipt);
  }

}