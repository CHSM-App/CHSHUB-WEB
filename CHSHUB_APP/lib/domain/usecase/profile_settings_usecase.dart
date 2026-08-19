import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/domain/models/vehicle.dart';
import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/domain/repository/profile_settings_repository.dart';

class ProfileSettingsUseCase {
  // Add your methods and properties here

  final ProfileSettingsRepository profileSettingsRepository;

  ProfileSettingsUseCase(this.profileSettingsRepository);

    Future<List<BasicInfo>> getFamilyMembers(int fId) {
    return profileSettingsRepository.getFamilyMembers(fId);
  }

  Future<List<Vehicle>> getVehicleList(int fid, String societyId) {
    return profileSettingsRepository.getVehicleList(fid, societyId);
  }

  Future<dynamic> addFamilyMember(int oId, String fName, String contact, String relation, String societyID) {
    return profileSettingsRepository.addFamilyMember(oId, fName, contact, relation, societyID);
  }

  Future<dynamic> deleteFamilyMember(int oExId){
    return profileSettingsRepository.deleteFamilyMember(oExId);
  }

  Future<dynamic> deleteFamilyVehicle(int vehicleId){
    return profileSettingsRepository.deleteFamilyVehicle(vehicleId);
  }

  Future<dynamic> addFamilyVehicle(Vehicle vehicle) {
    return profileSettingsRepository.addFamilyVehicle(vehicle);
  }

  Future<List<Helper>> getFamilyMemberHelper(int fId) {
    return profileSettingsRepository.getFamilyMemberHelper(fId);
  }

  Future<List<Visitor>> getFrequentEntries(int fId){
    return profileSettingsRepository.getFrequentEntries(fId);
  }

  Future<List<Helper>> getPersonList() {
    return profileSettingsRepository.getPersonList();
  }

  Future<Helper> addFamilyHelper(Helper helper) {
    return profileSettingsRepository.addFamilyHelper(helper);
  }

  Future<dynamic> deleteFamilyHelper(int helperId){
    return profileSettingsRepository.deleteFamilyHelper(helperId);
  }

}