import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/domain/repository/alert_repository.dart';

class AlertImpl implements AlertRepository {
  final ApiService apiService;

  AlertImpl(this.apiService);



  @override
  Future<dynamic> addOwnerMessage(int flatId, String Message, String Type, String SocietyId,String Messagesub,int OwnerId,int Ownertype){
    return apiService.addOwnerMessage(flatId, Message, Type, SocietyId,Messagesub,OwnerId,Ownertype);
  }
  @override
  Future<dynamic> addAlertMessage(int flatId, String Type, String SocietyId) {
    return apiService.addAlertMessage(flatId, Type, SocietyId);
  }
  @override
  Future<dynamic> sendNotification(SendNotification notification) {
    return apiService.sendMessage(notification);
  }

  @override
  Future<dynamic> sendDataMessage(SendNotification notification) {
    return apiService.sendDataMessage(notification);
  }

  @override
  Future<dynamic> insertToken(int ownerId, String type, String token) {
    return apiService.insertToken(ownerId, type, token);
  }

  
}
