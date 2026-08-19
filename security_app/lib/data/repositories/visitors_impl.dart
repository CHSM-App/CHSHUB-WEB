import 'dart:io';

import 'package:security_app/data/api/api_service.dart';
import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/domain/repository/visitors_repo.dart';

class VisitorsImpl implements VisitorsRepo {
  final ApiService apiService;

  VisitorsImpl(this.apiService);

 

  @override
  Future<Visitors> insertVisitor(Visitors visitors) {
    return apiService.insertVisitor(visitors);
  }
  @override
  Future<Visitors> updateVisitor(Vid, caption, userId) {
    return apiService.updateVisitor(Vid, caption, userId);
  }
  @override
  Future<dynamic> addGuest(int flatId, String guestName, String preDate, String contactNo,String purpose,String societyId,String location) {
    return apiService.addGuest(flatId, guestName, preDate, contactNo,purpose,societyId,location);
  }
  
  @override
  Future<dynamic> addCab(int flatId, String cabName, String vehicleNo, String preDate, String contactNo,String company,String societyId,String location) {
    return apiService.addCab(flatId, cabName, vehicleNo, preDate, contactNo,company,societyId,location);
  }
    @override
  Future<dynamic> addDelivery(int flatId, String deliveryName, String preDate, String contactNo,String purpose,String vehicleNo,String company,String societyId ) {
    return apiService.addDelivery(flatId, deliveryName, preDate, contactNo, purpose,vehicleNo,company,societyId);
  }


  @override
  Future<dynamic> addService(int flatId, String serviceName, String preDate, String contactNo,String company,String vehicleNo,String societyId) {
    return apiService.addService(flatId, serviceName, preDate, contactNo,company,vehicleNo,societyId);
  }
  
 @override
 Future<dynamic>addVisitorProfile(File image, int visitorId) {
    return apiService.addVisitorProfile(image, visitorId);
  }
  
  @override
  Future<List<Visitors>> getRegularVisitor(String SocietyId) {
    return apiService.getRegularVisitor(SocietyId);
  }
  
  @override
  Future<List<Visitors>> getVisitorList(String SocietyId) {
     return apiService.getVisitorList(SocietyId);
  }

  @override
  Future<List<Visitors>> getVisitorHistory(String SocietyId, String startDate, String endDate) {
     return apiService.getVisitorHistory(SocietyId, startDate, endDate);
  }

    @override
  Future<dynamic> insertToken(int ownerId, String token) {
    return apiService.insertToken(ownerId, token);
  }
    @override
  Future<dynamic> updateInsideStatus(int visitorId) {
    return apiService.updateInsideStatus(visitorId);
  }

  @override
  Future<dynamic> updateWaitingStatus(int visitorId) {
    return apiService.updateWaitingStatus(visitorId);
  }
  @override
  Future<dynamic> updatePreVisitor(int? visitor_id, String guestName, String contactNo, String entryType) async {
    return apiService.updatePreVisitor(visitor_id, guestName, contactNo, entryType);
  }
}