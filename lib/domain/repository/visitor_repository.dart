import 'package:society_app/domain/models/visitor.dart';
 
abstract class VisitorRepository {
  // Fetch the list of visitors based on type and flat ID
    Future<List<Visitor>> getVisitorList(String predate,int flatId,);
  // Insert a new visitor
   Future<dynamic> addCab( String cabName,String vehicleNo, String preDate,String contactNo,String company,String societyId,int ownerId,int flatId);
    Future<dynamic> addService( String serviceName, String preDate,String contactNo,String company,String societyId,int ownerId,int flatId);
     Future<dynamic> addDelivery(String deliveryName, String preDate,String contactNo,String preference,String company,String societyId,int ownerId,int flatId);
    Future<dynamic> addGuest( String guestName, String preDate,String contactNo,String societyId,int ownerId,int flatId);
  // Delete an expected visitor by ID
  Future<Visitor> deleteExpectedVisitor(int visitorId,);
  Future<Visitor> visitorAction (Visitor visitor);
   Future<dynamic> updateWaitingStatus(int visitorId);

}



