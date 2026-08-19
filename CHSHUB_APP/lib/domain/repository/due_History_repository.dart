
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/domain/models/receipt.dart';

abstract class DueHistoryRepository {

  Future<List<DueHistory>> getDueHistory(int ownerId);

  Future<List<DueHistory>> getReceipt(int receiptId);
      Future<dynamic> addReceipt(Receipt receipt);
}