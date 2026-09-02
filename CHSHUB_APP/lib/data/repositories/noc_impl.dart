import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/noc_request.dart';
import 'package:society_app/domain/repository/noc_repository.dart';

class NocRepositoryImpl implements NocRepository {
  final ApiService apiService;

  NocRepositoryImpl(this.apiService);

  @override
  Future<dynamic> insertNocRequest(NocRequest request) {
    return apiService.insertNocRequest(request);
  }

  @override
  Future<List<NocRequest>> getNocRequests(int flatId) {
    return apiService.getNocRequests(flatId);
  }
}
