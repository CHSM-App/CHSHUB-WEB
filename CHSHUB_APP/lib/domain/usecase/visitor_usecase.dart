import 'package:society_app/domain/models/visitor.dart';
import 'package:society_app/domain/repository/visitor_repository.dart';

class VisitorUsecase {
  final VisitorRepository repository;

  VisitorUsecase(this.repository);

  Future<List<Visitor>> getVisitorList(String preDate, int flatId) async {
    return await repository.getVisitorList(preDate, flatId);
  }

  Future<dynamic> addCab(String cabName, String vehicleNo, String preDate, String contactNo,String company,String societyId,int ownerId,int flatId) async {
    return await repository.addCab( cabName, vehicleNo, preDate, contactNo,company,societyId,ownerId,flatId);
  }

  Future<dynamic> addService( String serviceName, String preDate, String contactNo,String company,String societyId,int ownerId,int flatId) async {
    return await repository.addService(serviceName, preDate, contactNo,company,societyId,ownerId,flatId);
  }

  Future<dynamic> addDelivery(String deliveryName, String preDate, String contactNo,String preference,String company,String societyId,int ownerId,int flatId) async {
    return await repository.addDelivery( deliveryName, preDate, contactNo,preference,company,societyId,ownerId,flatId);
  }

  Future<dynamic> addGuest( String guestName, String preDate, String contactNo,String societyId,int ownerId,int flatId) async {
    return await repository.addGuest( guestName, preDate, contactNo,societyId,ownerId,flatId);
  }

  Future<Visitor> deleteExpectedVisitor(int visitorId) async {
    return await repository.deleteExpectedVisitor(visitorId);
  }

  Future<Visitor> visitorAction(Visitor visitor) async{
    return await repository.visitorAction(visitor);
  }

  Future<dynamic>updateWaitingStatus(int visitorId) {
    return repository.updateWaitingStatus(visitorId);
  }

}
