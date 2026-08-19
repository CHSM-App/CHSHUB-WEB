import 'package:society_app/domain/repository/directory_repository.dart';
import '../models/directory.dart';

class DirectoryUsecase {
  final DirectoryRepository repository;

  DirectoryUsecase(this.repository);

  Future<List<Directory>> getCommitteeMembers(String societyId) async {
    return await repository.getCommitteeMembers(societyId);
  }

  Future<List<Directory>> getAllTokens(String societyId) async {
    return await repository.getAllTokens(societyId);
  }

  Future<List<Directory>> getEmergencyContacts() async {
    return await repository.getEmergencyContacts();
  }

  Future<List<Directory>> getNeighbours(String wName) async {
    return await repository.getNeighbours(wName);
  }

  Future<List<Directory>> getVendors(String societyId) async {
    return await repository.getVendors(societyId);
  }
}
