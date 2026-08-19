import 'package:security_app/domain/models/alert_notification.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/models/notification.dart';
import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/domain/repository/logindata_repo.dart';

class LoginUsercase {
  final LoginRepo logindataRepo;
  LoginUsercase(this.logindataRepo);
  Future<List<LoginData>> getLoginDetails(String contact) {
    return logindataRepo.getLoginDetails(contact);
  
  }


    Future<List<LoginData>> checkUser(String contact) {
    return logindataRepo.checkUser(contact);
  
  }
  Future<LoginData> updateGateKeeper1(int id, String contactNo, String name, String email, String address, String image) {
    return logindataRepo.updateGateKeeper1(id, contactNo, name, email, address, image);
  
  }
  
  Future<dynamic> updateGateKeeper(LoginData loginData) {
    return logindataRepo.UpdateGatekeeper(loginData);
  }
  Future<dynamic> updateToken(int staffId, String token) {
    return logindataRepo.updateToken(staffId, token);
  }
  Future<dynamic>sendMessage(SendNotification body){
    return logindataRepo.sendMessage(body);
  }
  Future<List<LoginData>> getAllTokens(String society,String type){
    return logindataRepo.getAllTokens(society, type);
  }
    Future<dynamic>sendDataMessage(SendNotification body){
    return logindataRepo.sendDataMessage(body);
  }
    Future<dynamic> deleteStaffImage(String staffId) {
    return logindataRepo.deleteStaffImage(staffId);
  }
    Future<dynamic> sendAlertNotifications(AlertNotification body) {
    return logindataRepo.sendAlertNotifications(body);
  }

      Future<List<Visitors>> getCommitteeContacts(String society_id) {
    return logindataRepo.getCommitteeContacts(society_id);
  }
}