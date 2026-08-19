import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/domain/repository/visitor_repository.dart';

class VisitorImpl implements VisitorRepository {
  final ApiService apiService;

  VisitorImpl(this.apiService);

  @override
  Future<List<Visitor>> getVisitorList(String preDate, int flatId) async {
    return await apiService.getVisitorList(preDate, flatId);
  }

  @override
  Future<Visitor> deleteExpectedVisitor(int visitorId) async {
    return await apiService.deleteExpectedVisitor(visitorId);
  }

  @override
  Future<dynamic> addCab(String cabName, String vehicleNo, String preDate, String contactNo,String company,String societyId,int ownerId,int flatId) {
    return apiService.addCab( cabName, vehicleNo, preDate, contactNo,company,societyId,ownerId,flatId);
  }

  @override
  Future<dynamic> addDelivery( String deliveryName, String preDate, String contactNo,String preference,String company,String societyId,int ownerId,int flatId ) {
    return apiService.addDelivery(deliveryName, preDate, contactNo, preference,company,societyId,ownerId,flatId);
  }

  @override
  Future<dynamic> addGuest(String guestName, String preDate, String contactNo,String societyId,int ownerId,int flatId) {
    return apiService.addGuest(guestName, preDate, contactNo,societyId,ownerId,flatId);
  }

  @override
  Future<dynamic> addService( String serviceName, String preDate, String contactNo,String company,String societyId,int ownerId,int flatId ) {
    return apiService.addService(serviceName, preDate, contactNo,company,societyId,ownerId,flatId);
  }

  @override
  Future<Visitor> visitorAction(Visitor visitor){
    return apiService.visitorAction(visitor);
  }

    @override
  Future<dynamic> updateWaitingStatus(int visitorId) {
    return apiService.updateWaitingStatus(visitorId);
  }
}
