import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/domain/models/directory.dart';
import 'package:security_app/domain/repository/directory_repo.dart';

class DirectoryImpl implements DirectoryRepo {
  final ApiService apiService;

  DirectoryImpl(this.apiService);

  @override
  Future<List<Directory>> getEmergencyContacts() {
    return apiService.getEmergencyContacts();
  }

  @override
  Future<List<Directory>> getNeighbours(int bId) {
    return apiService.getNeighbours(bId);
  }

  @override
  Future<List<Directory>> getCommitteeMembers(String societyId) {
    return apiService.getCommitteeMembers(societyId);
  }
}