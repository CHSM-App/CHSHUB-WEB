import 'dart:io';

import 'package:security_app/domain/models/visitors.dart';
import 'package:security_app/domain/repository/visitors_repo.dart';

class VisitorsUsercase {
  final VisitorsRepo repository;
  VisitorsUsercase(this.repository);
  Future<List<Visitors>> getVisitorsList(String society) {
    return repository.getVisitorList(society);
  }

  Future<List<Visitors>> getVisitorHistory(String society, String startDate, String endDate) {
    return repository.getVisitorHistory(society, startDate, endDate);
  }

  Future<List<Visitors>> getRegularVisitor(String society) {
    return repository.getRegularVisitor(society);
  }

  Future<Visitors> insertVisitor(Visitors visitors) {
    return repository.insertVisitor(visitors);
  }

  Future<Visitors> updateVisitor(V_id, caption, user_id) {
    return repository.updateVisitor(V_id, caption, user_id);
  }

  Future<dynamic> addGuest(
    int flatId,
    String guestName,
    String preDate,
    String contactNo,
    String purpose,
    String societyId,
    String location,
  ) async {
    return await repository.addGuest(
      flatId,
      guestName,
      preDate,
      contactNo,
      purpose,
      societyId,
      location,
    );
  }

  Future<dynamic> addCab(
    int flatId,
    String cabName,
    String vehicleNo,
    String preDate,
    String contactNo,
    String company,
    String societyId,
    String location,
  ) async {
    return await repository.addCab(
      flatId,
      cabName,
      vehicleNo,
      preDate,
      contactNo,
      company,
      societyId,
      location,
    );
  }

  Future<dynamic> addService(
    int flatId,
    String serviceName,
    String preDate,
    String contactNo,
    String company,
    String vehicleNo,
    String societyId,
  ) async {
    return await repository.addService(
      flatId,
      serviceName,
      preDate,
      contactNo,
      company,
      vehicleNo,
      societyId,
    );
  }

  Future<dynamic> addDelivery(
    int flatId,
    String deliveryName,
    String preDate,
    String contactNo,
    String purpose,
    String vehicleNo,
    String company,
    String societyId,
  ) async {
    return await repository.addDelivery(
      flatId,
      deliveryName,
      preDate,
      contactNo,
      purpose,
      vehicleNo,
      company,
      societyId,
    );
  }

  Future<dynamic> addVisitorProfile(File image, int visitorId) {
    return repository.addVisitorProfile(image, visitorId);
  }

  Future<dynamic> insertToken(int ownerId, String token) {
    return repository.insertToken(ownerId, token);
  }
   Future<dynamic>updateInsideStatus(int visitorId) {
    return repository.updateInsideStatus(visitorId);
  }
  Future<dynamic>updateWaitingStatus(int visitorId) {
    return repository.updateWaitingStatus(visitorId);
  }

  Future<dynamic> updatePreVisitor(int? visitor_id, String guestName, String contactNo, String entryType) async {
    return await repository.updatePreVisitor(visitor_id, guestName, contactNo, entryType);
  }
}
