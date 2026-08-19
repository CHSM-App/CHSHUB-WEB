import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/domain/models/alert_notification.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/models/notification.dart';
import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/domain/repository/logindata_repo.dart';

class LoginImpl implements LoginRepo {
  final ApiService apiService;

  LoginImpl(this.apiService);

  @override
  // Future<List<LoginData>> getLoginDetails(String contact) async {
  //   final result =  await apiService.getLoginDetails(contact);
  //   if (result.isNotEmpty) {
  //     await TokenStorage.saveValue("mobile", result[0].contactNo ?? 'N/A');
  //     debugPrint("Inserted mobile number: ${result[0].contactNo ?? 'N/A'}");
  //      await TokenStorage.saveValue("address", result[0].address ?? 'N/A');
  //       await TokenStorage.saveValue("email", result[0].email ?? 'N/A');
  //        await TokenStorage.saveValue("name", result[0].name ?? 'Unknown');
  //        await TokenStorage.saveValue("societyName", result[0].societyName?.toString() ?? '');
  //         await TokenStorage.saveValue("societyId", result[0].societyId?.toString() ?? '');
  //         await TokenStorage.saveValue("userId", result[0].staffId?.toString() ?? '0');
  //         await TokenStorage.saveValue("token", result[0].token?.toString() ?? '0');
  //   }
  //   return result ;
  // }
@override
Future<List<LoginData>> getLoginDetails(String contact) async {
  return await apiService.getLoginDetails(contact);
}

  @override
  Future<LoginData> updateGateKeeper1(int id, String contactNo, String name, String email, String address, String image) async {
    return await apiService.updateGateKeeper1(id, contactNo, name, email, address, image);
  }
  
  @override
  Future<List<LoginData>> checkUser(String contact) {
    return apiService.checkUser(contact);
  }
@override
  Future<dynamic> UpdateGatekeeper(LoginData loginData) {
    return apiService.updateGatekeeper(loginData.staffId!, loginData);
  }
 @override
  Future<dynamic> updateToken(int staffId, String token) {
    return apiService.updateToken(staffId, token);
  }

@override
Future<dynamic>sendMessage(SendNotification body){
  return apiService.sendMessage(body);
}

@override
Future<List<LoginData>> getAllTokens(String society,String type){
  return apiService.getAllTokens(society, type);
}

@override
Future<dynamic>sendDataMessage(SendNotification body){
  return apiService.sendDataMessage(body);
}

@override
  Future<dynamic> deleteStaffImage(String staffId) {
    return apiService.deleteStaffImage(staffId);
  }

@override
  Future<dynamic> sendAlertNotifications(AlertNotification body) {
    return apiService.sendAlertNotifications(body);
  }

@override
  Future<List<Visitors>> getCommitteeContacts(String society_id) {
    return apiService.getContacts(society_id);
  }
}