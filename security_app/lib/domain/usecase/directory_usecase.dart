import 'package:security_app/domain/models/directory.dart';
import 'package:security_app/domain/repository/directory_repo.dart';

class DirectoryUsecase {
  final DirectoryRepo directoryRepo;
  DirectoryUsecase(this.directoryRepo);
  Future<List<Directory>> getEmergencyContacts() {
    return directoryRepo.getEmergencyContacts();
  }
  Future<List<Directory>> getNeighbours(int bId) {
    return directoryRepo.getNeighbours(bId);
  }
  Future<List<Directory>> getCommitteeMembers(String societyId) { 
    return directoryRepo.getCommitteeMembers(societyId);



  }
}