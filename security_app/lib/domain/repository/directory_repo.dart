import 'package:security_app/domain/models/directory.dart';

abstract class DirectoryRepo {
  Future<List<Directory>> getEmergencyContacts();
  Future<List<Directory>> getNeighbours(int bId);
  Future<List<Directory>> getCommitteeMembers(String societyId);
}