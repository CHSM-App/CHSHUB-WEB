import 'package:society_app/domain/repository/broadcast_repository.dart';
import '../models/broadcast.dart';

class BroadcastUsecase {
  final BroadcastRepository repository;
  
  BroadcastUsecase(this.repository);

  Future<List<Broadcast>> getBroadcast(String societyId,int ownerId) {
    return repository.getBroadcast(societyId,ownerId);
  }

  Future<List<Broadcast>> getNotification(String societyId, int ownerId) {
    return repository.getNotification(societyId, ownerId);
  }

  Future<dynamic> updateNotificationStatus(int id) {
    return repository.updateNotificationStatus(id);
  }

  Future<dynamic> markAllNotificationsSeenByType(String societyId, int ownerId, String notificationType) {
    return repository.markAllNotificationsSeenByType(societyId, ownerId, notificationType);
  }

  Future<List<Broadcast>> getNotificationDetails(String society, String type, int id) {
    return repository.getNotificationDetails(society, type, id);
  }

  Future<dynamic> insertNotification(Broadcast broadcast) {
    return repository.insertNotification(broadcast);
  }
}
