import 'dart:io';

import 'package:security_app/domain/models/visitors.dart';

abstract class VisitorsRepo {
 
  Future<Visitors> insertVisitor( Visitors visitors);
  Future<Visitors> updateVisitor(V_id, caption, user_id);
    Future<dynamic> addGuest(int flatId, String guestName, String preDate,String contactNo,String purpose,String societyId,String location);
    Future<dynamic> addCab(int flatId, String cabName, String vehicleNo, String preDate,String contactNo,String company,String societyId,String location);
    Future<dynamic> addDelivery(int flatId, String deliveryName, String preDate,String contactNo,String purpose,String vehicleNo,String company,String societyId);
    Future<dynamic> addService(int flatId, String serviceName, String preDate,String contactNo,String company,String vehicleNo,String societyId); 

 Future<List<Visitors>> getVisitorList( String SocietyId);
  Future<List<Visitors>> getVisitorHistory(String SocietyId, String startDate, String endDate);
  Future<List<Visitors>> getRegularVisitor( String SocietyId);
  Future<dynamic>addVisitorProfile(File image, int visitorId);
    Future<dynamic> insertToken(int ownerId, String token);
      Future<dynamic> updateInsideStatus(int visitorId);
        Future<dynamic> updateWaitingStatus(int visitorId);

  Future<dynamic> updatePreVisitor(int? visitor_id, String guestName, String contactNo, String entryType);
}