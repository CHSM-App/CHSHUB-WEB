import '../models/directory.dart';

abstract class DirectoryRepository {
  // Fetch the list of emergency contacts
  Future<List<Directory>> getEmergencyContacts();

  // Fetch the list of committee members based on society ID
  Future<List<Directory>> getCommitteeMembers(String societyId);

  // Fetch all tokens for a given society ID
  Future<List<Directory>> getAllTokens(String societyId);


  // Fetch the list of vendors based on society ID
  Future<List<Directory>> getVendors(String societyId);

  // Fetch the list of neighbours based on ward name
  Future<List<Directory>> getNeighbours(String wName);
}