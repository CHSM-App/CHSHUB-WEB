import 'package:society_app/domain/models/basicinfo.dart';
import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/domain/models/vehicle.dart';
import 'package:society_app/domain/models/visitor.dart';

abstract class ProfileSettingsRepository {
    Future<List<BasicInfo>> getFamilyMembers(int fId);
  Future<List<Vehicle>> getVehicleList(int fid, String societyId);

  Future<dynamic> addFamilyMember(int oId, String fName, String contact, String relation, String societyID);

  Future<dynamic> deleteFamilyMember(int oExId);
  Future<dynamic> deleteFamilyVehicle(int vehicleId);
  Future<List<Helper>> getFamilyMemberHelper(int fId);
  Future<dynamic> addFamilyVehicle(Vehicle vehicle);
  Future<List<Visitor>> getFrequentEntries(int fId);
  Future<List<Helper>> getPersonList();
  Future<Helper> addFamilyHelper(Helper helper);
  Future<dynamic> deleteFamilyHelper(int helperId);

}