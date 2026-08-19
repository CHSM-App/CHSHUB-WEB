import 'package:society_app/domain/repository/alert_repository.dart';

class AlertUsecase {
  final AlertRepository repository;

  AlertUsecase(this.repository);

  Future<dynamic> addOwnerMessage(int flatId, String Message, String Type, String SocietyId,String Messagesub,int OwnerId,int Ownertype) {
    return repository.addOwnerMessage(flatId, Message, Type, SocietyId,Messagesub,OwnerId,Ownertype);
  }
  Future<dynamic> addAlertMessage(int flatId, String type, String societyId) {
    return repository.addAlertMessage(flatId, type, societyId);
  }
  Future<dynamic> sendNotification(notification) {
    return repository.sendNotification(notification);
  }
  Future<dynamic> insertToken(int ownerId, String type, String token) {
    return repository.insertToken(ownerId, type, token);
  }

  Future<dynamic> sendDataMessage(notification) {
    return repository.sendDataMessage(notification);
  }

}
