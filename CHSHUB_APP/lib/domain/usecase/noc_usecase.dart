import 'package:society_app/domain/models/noc_request.dart';
import 'package:society_app/domain/repository/noc_repository.dart';

class NocUsecase {
  final NocRepository repository;

  NocUsecase(this.repository);

  Future<dynamic> insertNocRequest(NocRequest request) {
    return repository.insertNocRequest(request);
  }

  Future<List<NocRequest>> getNocRequests(int flatId) {
    return repository.getNocRequests(flatId);
  }
}
