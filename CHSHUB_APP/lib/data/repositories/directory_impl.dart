import 'package:society_app/domain/repository/directory_repository.dart';

import '../../domain/models/directory.dart';
import '../api/api_service.dart';

class DirectoryRepositoryImpl implements DirectoryRepository {
  final ApiService apiService;

  DirectoryRepositoryImpl(this.apiService);

  @override
  Future<List<Directory>> getCommitteeMembers(String societyId) async {
    return await apiService.getCommitteeMembers(societyId);
  }

  @override
  Future<List<Directory>> getAllTokens(String societyId) async {
    return await apiService.getAllTokens(societyId);
  }
  
  @override
  Future<List<Directory>> getEmergencyContacts() async {
    return await apiService.getEmergencyContacts();
  }
  
  @override
  Future<List<Directory>> getNeighbours(String wName) async {
    return await apiService.getNeighbours(wName); 
  }
  
  @override
  Future<List<Directory>> getVendors(String societyId) async {
    return await apiService.getVendors(societyId);
  }
}
