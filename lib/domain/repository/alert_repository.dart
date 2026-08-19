 
import 'package:society_app/domain/models/notification.dart';

abstract class AlertRepository {
   
  Future<dynamic> addOwnerMessage(int flatId,String Message, String Type, String SocietyId, String messagesub, int ownerId, int ownertype);
  Future<dynamic> addAlertMessage(int flatId, String Type, String SocietyId);
  Future<dynamic> sendNotification(SendNotification notification);
  Future<dynamic> insertToken(int ownerId, String type, String token);
  Future<dynamic> sendDataMessage(SendNotification notification);
}