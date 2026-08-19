import '../models/broadcast.dart';

abstract class BroadcastRepository {
  // Fetch the list of broadcasts
  Future<List<Broadcast>> getBroadcast(String societyId,int ownerId );
  Future<List<Broadcast>> getNotification( String societyId, int ownerId );
  Future<dynamic> updateNotificationStatus(  int id);
  Future<dynamic> markAllNotificationsSeenByType(String societyId, int ownerId, String notificationType);

  Future<List<Broadcast>> getNotificationDetails( String society, String type, int id, );

  Future<dynamic> insertNotification(Broadcast broadcast );
} 
