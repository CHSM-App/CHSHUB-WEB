
import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/domain/models/vehicle.dart';
import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/domain/repository/profile_settings_repository.dart';
import '../../domain/models/basicinfo.dart';
import '../api/api_service.dart';

class ProfileSettingsImpl implements ProfileSettingsRepository {
    final ApiService apiService;
    ProfileSettingsImpl(this.apiService);
  
  @override
  Future<List<BasicInfo>> getFamilyMembers(int fId) {
    return apiService.getFamilyMembers(fId);
  }
  
  @override
  Future<List<Vehicle>> getVehicleList(int fid, String societyId) {
    return apiService.getVehicleList(fid, societyId);
  }

  @override
  Future<List<Helper>> getFamilyMemberHelper(int fId) {
    return apiService.getFamilyMemberHelper(fId); 
  }

    @override
  Future<dynamic> addFamilyMember(int oId, String fName, String contact, String relation, String societyID) {
    return apiService.addFamilyMember(oId, fName, contact, relation, societyID);
  }

  @override
  Future<dynamic> addFamilyVehicle(Vehicle vehicle) {
    return apiService.addFamilyVehicle(vehicle);
  }

  @override
  Future<dynamic> deleteFamilyMember(int memberId){
    return apiService.deleteFamilyMember(memberId);
  }

  @override
  Future<dynamic> deleteFamilyVehicle(int vehicleId){
    return apiService.deleteFamilyVehicle(vehicleId);
  }

  @override
  Future<List<Visitor>> getFrequentEntries(int fId){
    return apiService.getFrequentEntries(fId);
  }

  @override
  Future<List<Helper>> getPersonList() {
    return apiService.getPersonList();
  }

  @override
  Future<Helper> addFamilyHelper(Helper helper) {
    return apiService.addFamilyHelper(helper);
  }

  @override
  Future<dynamic> deleteFamilyHelper(int id) {
    return apiService.deleteFamilyHelper(id);
  }

}