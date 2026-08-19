import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/domain/models/receipt.dart';
import 'package:society_app/domain/repository/due_History_repository.dart';

class DueHistoryImpl implements DueHistoryRepository {
  final ApiService apiService;
  DueHistoryImpl(this.apiService);
  @override
  Future<List<DueHistory>> getDueHistory(int ownerId) async {
    try {
      final response = await apiService.getDueHistory(ownerId,);
      return response;
    } catch (e) {
      throw Exception('Failed to load due history: $e');
    }
  }

  @override
  Future<List<DueHistory>> getReceipt(int receiptId) async {
    try {
      final response = await apiService.getReceipt(receiptId);
      return response;
    } catch (e) {
      throw Exception('Failed to load Receipt: $e');
    }
  }
 @override
  Future<dynamic> addReceipt(Receipt receipt) {
    return apiService.addReceipt(receipt);
  }
}