import 'package:security_app/domain/models/alert_notification.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/models/notification.dart';
import 'package:security_app/domain/models/visitors.dart';

abstract class LoginRepo {
  Future<List<LoginData>> getLoginDetails(String contact);
  Future<LoginData> updateGateKeeper1(int id, String contactNo, String name, String email, String address, String image);
  Future<List<LoginData>> checkUser(String contact);
   Future<dynamic> UpdateGatekeeper(LoginData loginData); 
      Future<dynamic> updateToken(int staffId, String token);
      Future<dynamic>sendMessage(SendNotification body);
      Future<List<LoginData>> getAllTokens(String society,String type);
          Future<dynamic>sendDataMessage(SendNotification body);
          Future<dynamic> deleteStaffImage(String staffId);
 Future<dynamic> sendAlertNotifications(AlertNotification body);
    Future<List<Visitors>> getCommitteeContacts(String society_id);
 
}
