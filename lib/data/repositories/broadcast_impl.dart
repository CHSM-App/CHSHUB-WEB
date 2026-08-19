import '../../domain/models/broadcast.dart';
import '../../domain/repository/broadcast_repository.dart';
import '../api/api_service.dart';

class BroadcastRepositoryImpl implements BroadcastRepository {
  final ApiService apiService;

  BroadcastRepositoryImpl(this.apiService);

  @override
  Future<List<Broadcast>> getBroadcast(String societyId,int ownerId) {
    return apiService.getBroadcast(societyId,ownerId);
  }

  @override
  Future<List<Broadcast>> getNotification(String societyId, int ownerId) {
    return apiService.getNotification(societyId, ownerId);
  }

  @override
  Future<dynamic> updateNotificationStatus(int id) {
    return apiService.updateNotificationStatus(id);
  }

  @override
  Future<dynamic> markAllNotificationsSeenByType(String societyId, int ownerId, String notificationType) {
    return apiService.markAllNotificationsSeenByType({
      "society_id": societyId,
      "owner_id": ownerId,
      "notification_type": notificationType,
    });
  }

  @override
  Future<List<Broadcast>> getNotificationDetails(String society, String type, int id) {
    return apiService.getNotificationDetails(society, type, id);
  }

  @override
  Future<dynamic> insertNotification(Broadcast broadcast) {
    return apiService.insertNotification(broadcast);
  }
}
