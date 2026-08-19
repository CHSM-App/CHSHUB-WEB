import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:society_app/domain/models/due_History.dart';
import 'package:society_app/domain/models/facilities.dart';
import 'package:society_app/domain/models/maintenance.dart';
import 'package:society_app/domain/models/notification.dart';
import 'package:society_app/domain/models/receipt.dart';
import 'package:society_app/domain/models/test_payment.dart';
import 'package:society_app/domain/models/token_response.dart';
import 'package:society_app/domain/models/vehicle.dart';

import '../../core/constant.dart';
import '../../domain/models/all_spinner.dart';
import '../../domain/models/basicinfo.dart';
import '../../domain/models/broadcast.dart';
import '../../domain/models/directory.dart';
import '../../domain/models/helpdesk.dart';
import '../../domain/models/helpdesk_comment.dart';
import '../../domain/models/helper.dart';
import '../../domain/models/product_sell.dart';
import '../../domain/models/visitor.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  @GET("/")
  Future<HttpResponse> checkHealth();
  // Basic Info
  @POST("test/create-order")
  Future<dynamic> createPaymentOrder(@Body() TestPayment payment);
  @POST("test/verify-payment")
  Future<dynamic> verifyPayment(@Body() TestPayment payment);
  @GET("login/Home/CheckPhone")
  Future<List<BasicInfo>> checkPhoneNumber(@Query("pre_mob") String mobile);

  @GET("login/Otp/CheckUser")
  Future<List<BasicInfo>> checkUser(@Query("pre_mob") String mobile);

  @POST("login/CreateLogin")
  Future<TokenResponse> createLogin(@Body() TokenResponse tokenResponse);

  @POST("login/refreshAccessToken")
  Future<TokenResponse> refreshAccessToken(@Body() TokenResponse tokenResponse);
  @POST("login/logout")
  Future<TokenResponse> logout(@Body() TokenResponse tokenResponse);
  @GET("/users/Home/BasicInfo")
  Future<List<BasicInfo>> getBasicInfo(
    @Query("pre_mob") String preMob,
    @Query("fId") int fId,
    @Query("OwnerId") int ownerId,
  );

  @GET("/getProfileEdit")
  Future<BasicInfo> getProfileEdit(
    @Query("preMob") String preMob,
    @Query("oId") int oId,
    @Query("dob") String dob,
    @Query("type") String type,
  );

  @GET("/getGenderEdit")
  Future<BasicInfo> getGenderEdit(
    @Query("preMob") String preMob,
    @Query("oId") int oId,
    @Query("gender") String gender,
    @Query("type") String type,
  );

  @GET("users/FamilyMembers/{flat_id}")
  Future<List<BasicInfo>> getFamilyMembers(@Path("flat_id") int flatId);

  @GET("users/FamilyMemberHelper/{flat_id}")
  Future<List<Helper>> getFamilyMemberHelper(@Path("flat_id") int flatId);

  @GET("users/getFrequentEntry/{flat_id}")
  Future<List<Visitor>> getFrequentEntries(@Path("flat_id") int flatId);

  @GET("users/familyHelper/getPersonList")
  Future<List<Helper>> getPersonList();

  @GET("users/VehicleList/{flat_id}/{society_id}")
  Future<List<Vehicle>> getVehicleList(
    @Path("flat_id") int flatId,
    @Path("society_id") String societyId,
  );

  @GET("users/FindHelper/{society}")
  Future<List<Helper>> getHelperList(@Path("society") String society);

  @GET("users/HelperDetails/{society}")
  Future<List<Helper>> getHelperDetails(@Path("society") String society);
  @GET("users/FindHelperDetails/{helper_id}/{type}")
  Future<List<Helper>> FindHelperDetails(
    @Path("helper_id") int helperId,
    @Path("type") String type,
  );

  @GET("users//FindHelper/Info/worksAt/{helper_id}/{type}")
  Future<List<Helper>> FindHelperInfo(
    @Path("helper_id") int helperId,
    @Path("type") String type,
  );

  @GET("users//FindHelper/Info/Review/{helper_id}/{type}")
  Future<List<Helper>> HelperReview(
    @Path("helper_id") int helperId,
    @Path("type") String type,
  );

  @GET("/getEmailEdit")
  Future<BasicInfo> getEmailEdit(
    @Query("preMob") String preMob,
    @Query("oId") int oId,
    @Query("email") String email,
    @Query("type") String type,
  );

  @GET("/getMobileNoEdit")
  Future<BasicInfo> getMobileNoEdit(
    @Query("oId") int oId,
    @Query("preMob") String preMob,
    @Query("type") String type,
  );

  @GET("/updateSetting")
  Future<BasicInfo> updateSetting(
    @Query("oId") int oId,
    @Query("mobile") String mobile,
    @Query("type") String type,
    @Query("phone") int phone,
    @Query("email") int email,
    @Query("gate") int gate,
  );

  @GET("/updateHomeNo")
  Future<BasicInfo> updateHomeNo(
    @Query("preMob") String preMob,
    @Query("fId") int fId,
    @Query("homeNo") String homeNo,
  );

  @GET("/fetchHomeNo")
  Future<List<BasicInfo>> fetchHomeNo(
    @Query("preMob") String preMob,
    @Query("fId") int fId,
  );

  @GET("/deactivateAccount")
  Future<BasicInfo> deactivateAccount(
    @Query("oId") int oId,
    @Query("type") String type,
  );

  @GET("users/Home/TotalDue/{flat_id}")
  Future<dynamic> getTransaction(@Path("flat_id") int flatId);

  // Helpdesk
  @GET("users/Helpdesk/")
  Future<List<HelpdeskRequest>> getHelpdeskList(
    @Query("societyID") String societyID,
    @Query("ownerID") int ownerID,
  );
  

  @POST("insert/Helpdesk")
  Future<dynamic> insertHelpdesk(@Body() HelpdeskRequest helpDesk);

  @GET("users/HelpRequestById")
  Future<List<HelpdeskRequest>> getRequestById(@Query("id") int id);

  // Helpdesk Comments
  @GET("users/helpdeskComments")
  Future<List<HelpdeskComment>> getComments(@Query("id") int id);

  @POST("insert/community/comments")
  Future<dynamic> insertComments(@Body() HelpdeskComment comment);

  // Visitors
  @GET('users/visitor/{pre_date}/{flat_id}')
  Future<List<Visitor>> getVisitorList(
    @Path('pre_date') String predate,
    @Path('flat_id') int flatId,
  );

  @POST('insert/AddVisitor/Service')
  Future<dynamic> addService(
    @Query("v_name") String serviceName,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("company") String company,
    @Query("society_id") String societyId,
    @Query("owner_id") int ownerId,
    @Query("flat_id") int flatId,
  );

  @POST('insert/AddVisitor/Delivery')
  Future<dynamic> addDelivery(
    @Query("v_name") String deliveryName,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("preference") String preference,
    @Query("company") String company,
    @Query("society_id") String societyId,
    @Query("owner_id") int ownerId,
    @Query("flat_id") int flatId,
  );
  @POST('insert/AddVisitor/Cab')
  Future<dynamic> addCab(
    @Query("v_name") String cabName,
    @Query("vehical_no") String vehicleNo,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("company") String company,
    @Query("society_id") String societyId,
    @Query("owner_id") int ownerId,
    @Query("flat_id") int flatId,
  );

  @POST('insert/visitorAction')
  Future<Visitor> visitorAction(@Body() Visitor visitor);

  @POST('insert/AddVisitor/Guest')
  Future<dynamic> addGuest(
    @Query("v_name") String visitorName,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("society_id") String societyId,
    @Query("owner_id") int ownerId,
    @Query("flat_id") int flatId,
  );

  @DELETE('DeleteExpectedVisitor/{v_id}')
  Future<Visitor> deleteExpectedVisitor(@Path('v_id') int visitorId);

  @DELETE('Delete/Helper/Review/{id}')
  Future<Helper> deleteHelperReview(@Path('id') int reviewId);

  @DELETE('DeleteFamilyMember/{id}')
  Future<dynamic> deleteFamilyMember(@Path('id') int oExId);

  @DELETE('DeleteFamilyVehicle/{id}')
  Future<dynamic> deleteFamilyVehicle(@Path('id') int id);

  @DELETE('/familyHelper/delete/{id}')
  Future<dynamic> deleteFamilyHelper(@Path('id') int id);

  // Broadcast
  @GET("users/Community/Broadcast")
  Future<List<Broadcast>> getBroadcast(
    @Query("society_id") String societyId,
    @Query("owner_id") int ownerId,
  );

  // Emergency Contacts
  @GET("users/more/EmergencyContacts")
  Future<List<Directory>> getEmergencyContacts();

  // Vendors
  @GET("users/more/Vendors/{society_id}")
  Future<List<Directory>> getVendors(@Path("society_id") String societyId);

  // Neighbours
  @GET("users/more/Neighbours/{w_name}")
  Future<List<Directory>> getNeighbours(@Path("w_name") String wName);

  // Committee Members
  @GET("users/more/Committee/{society_id}")
  Future<List<Directory>> getCommitteeMembers(
    @Path("society_id") String societyId,
  );

  @GET("notify/Admin/Society/GetAllToken/{society_id}")
  Future<List<Directory>> getAllTokens(@Path("society_id") String societyId);

  // Notifications
  @GET("users/Notifications/{society_id}/{owner_id}")
  Future<List<Broadcast>> getNotification(
    @Path("society_id") String societyId,
    @Path("owner_id") int ownerId,
  );

  @POST("insert/Notifications/updateStatus/{id}")
  Future<dynamic> updateNotificationStatus(@Path("id") int id);

  @POST("insert/Notifications/markAllSeen")
  Future<dynamic> markAllNotificationsSeenByType(
    @Body() Map<String, dynamic> body,
  );

  @GET("users/NotificationDetails/{society}/{type}/{id}")
  Future<List<Broadcast>> getNotificationDetails(
    @Path("society") String society,
    @Path("type") String type,
    @Path("id") int id,
  );

  @POST("notify/insert/notification")
  Future<dynamic> insertNotification(@Body() Broadcast broadcast);

  @GET("users/facilities/{society_id}")
  Future<List<Facilities>> getFacilities(@Path("society_id") String societyId);

  @GET("users/Facilities/BookingList/{flat_no}")
  Future<List<Facilities>> getBookedFacilities(@Path("flat_no") int userId);

  @GET("/users/Home/DueHistory/{owner_id}")
  Future<List<DueHistory>> getDueHistory(@Path("owner_id") int ownerId);

  @GET("/users/Home/BasicInfo/{pre_mob}/{flat_id}")
  Future<List<BasicInfo>> getProfile(
    @Path("pre_mob") String preMob,
    @Path("flat_id") int flatId,
  );
  
  @MultiPart()
  @POST("upload/HelpdeskImages")
  Future<dynamic> addHelpdeskImages(
    @Part(name: "image") File image,
    @Part(name: "helpdesk_id") String helpdeskId,
  );
  @GET("users/facility/Slot/{facility_id}/{date}")
  Future<List<Facilities>> getFacilitySlots(
    @Path("facility_id") int facilityId,
    @Path("date") String date,
  );

  @POST("insert/Facilities/Booking")
  Future<dynamic> bookFacility(@Body() Facilities facility);

  @POST('insert/userProfile/update')
  Future<dynamic> updateProfile(@Body() BasicInfo basicInfo);

  @POST("insert/AddProduct")
  Future<dynamic> addProduct(@Body() ProductSell product);

  @MultiPart()
  @POST("upload/ProductImages")
  Future<dynamic> addProductImages(
    @Part(name: "image") File image,
    @Part(name: "product_id") String productId,
  );
  @MultiPart()
  @POST("upload/ProfilePhoto")
  Future<dynamic> addProfileImage(
    @Part(name: "image") File image,
    @Part(name: "owner_id") String ownerId,
    @Part(name: "loginType") String loginType,
  );
  @POST("notify/OwnerApp/Insert/NewToken")
  Future<dynamic> insertToken(
    @Query("owner_id") int ownerId,
    @Query("type") String type,
    @Query("token") String token,
  );

  @POST("notify/send-datamessage-security")
  Future<dynamic> sendDataMessage(@Body() SendNotification body);

  @POST("notify/send-notifications")
  Future<dynamic> sendMessage(@Body() SendNotification body);

  @GET("users/ProductBuy/ViewProduct/{product_id}")
  Future<List<ProductSell>> viewProduct(@Path("product_id") int productId);

  @GET("users/ProductBuy/{societyId}")
  Future<List<ProductSell>> productList(@Path("societyId") String societyId);
  // Notifications
  @GET("users/OwnerProductBuy/{societyId}/{ownerId}")
  Future<List<ProductSell>> ownerProductList(
    @Path("societyId") String societyId,
    @Path("ownerId") int ownerId,
  );
  
  @GET("users/category")
  Future<List<AllSpinner>> getAllComplainTypes();

  @DELETE('DeleteProduct/{product_id}')
  Future<dynamic> deleteProduct(@Path('product_id') int productId);

  @POST('insert/Helpdesk/UpdateRequest')
  Future<dynamic> updateRequest(
    @Query("status") int status,
    @Query("comment_id") int commentId,
    @Query("helpdesk_id") int helpdeskId,
  );

  @POST("insert/Helper/AddReview")
  Future<dynamic> addReview(@Body() Helper helper);

  @POST('insert/familyHelper/Add')
  Future<Helper> addFamilyHelper(@Body() Helper helper);

  @POST('insert/OwnerMessages')
  Future<dynamic> addOwnerMessage(
    @Query("flat_id") int flatId,
    @Query("messages") String Message,
    @Query("type") String Type,
    @Query("society_id") String SocietyId,
    @Query("message_sub") String Messagesub,
    @Query("owner_id") int OwnerId,
    @Query("owner_type") int Ownertype,
  );
  @POST('insert/SecurityAlert')
  Future<dynamic> addAlertMessage(
    @Query("flat_id") int flatId,
    @Query("type") String Type,
    @Query("society_id") String SocietyId,
  );

  @POST('insert/familyMember')
  Future<dynamic> addFamilyMember(
    @Query("o_id") int ownerId,
    @Query("f_name") String fName,
    @Query("contact") String contact,
    @Query("relation") String relation,
    @Query("society_id") String societyId,
  );

  @GET('users/FamilyMembers/{flat_id}')
  Future<List<BasicInfo>> familyMemberList(@Path('flat_id') int flatId);

  @GET('users/HelperList/{flat_id}/{society_id}')
  Future<List<Helper>> helperList(
    @Path('flat_id') int flatId,
    @Path('society_id') String societyId,
  );

  @GET('users/VehicleList/{flat_id}/{society_id}')
  Future<List<Vehicle>> vehicleList(
    @Path('flat_id') int flatId,
    @Path('society_id') String societyId,
  );
  @GET('users/Maintenance/{flat_id}/{bill_id}')
  Future<List<Maintenance>> maintenanceList(
    @Path('flat_id') int flatId,
    @Path('bill_id') int billId,
  );
  @GET('users/Receipt/{receipt_id}')
  Future<List<DueHistory>> getReceipt(@Path('receipt_id') int receiptId);

  @GET("users/SocietyPolls/{user_id}/{society_id}/{audience}")
  Future<dynamic> getPolls(
    @Path("user_id") int userId,
    @Path("society_id") String societyId,
    @Path("audience") int audience,
  );

  @POST("insert/polls/{pollId}/vote")
  Future<dynamic> addPollVote(
    @Path("pollId") int pollId,
    @Body() Map<String, dynamic> body,
  );

  @PUT("/polls/votes/{votingId}")
  Future<dynamic> updatePollVote(
    @Path("votingId") int votingId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE("polls/votes/{votingId}/{userId}")
  Future<dynamic> deleteVotes(
    @Path("votingId") int votingId,
    @Path("userId") int userId,
  );

  @POST("insert/familyVehicle/Add")
  Future<dynamic> addFamilyVehicle(@Body() Vehicle vehicle);

  @POST("insert/DeleteProfilePhoto")
  Future<dynamic> deleteProfileImage(
    @Field("owner_id") String ownerId,
    @Field("loginType") String loginType,
  );

  @MultiPart()
  @POST("upload/OwnerDocuments")
  Future<dynamic> addOwnerDocuments(
    @Part(name: "docs") File documents,
    @Part(name: "flat_id") int flatId,
    @Part(name: "doc_name") String documentName,
  );

  @GET('users/OwnerDocumentsList/{flat_id}')
  Future<List<BasicInfo>> ownerDocumentsList(@Path('flat_id') int flatId);

  @DELETE('DeleteDocuments/{id}')
  Future<dynamic> deleteDocuments(@Path('id') int documentId);

  @POST('insert/Helper/AssignToFlat')
  @POST('insert/Helper/AssignToFlat')
  Future<dynamic> helperAssignFlat(@Body() Helper helper);

  @POST("insert/AddReceipt")
  Future<dynamic> addReceipt(@Body() Receipt receipt);


  @DELETE(
    'Delete/Helper/UnAssignToFlat/{userfull_contact_id}/{helper_work_id}/{f_id}',
  )
  @DELETE(
    'Delete/Helper/UnAssignToFlat/{userfull_contact_id}/{helper_work_id}/{f_id}',
  )
  Future<Helper> unAssignflat(
    @Path('userfull_contact_id') int usefullContactId,
    @Path('helper_work_id') int workId,
    @Path('f_id') int flatId,
  );

  @DELETE('Delete/UnAssignToFlat/{helper_work_id}')
  Future<Helper> flatunAssign(@Path('helper_work_id') int workId);

  @POST('insert/updateProduct')
  @POST('insert/updateProduct')
  Future<dynamic> updateProduct(@Body() ProductSell productsell);

   @GET("users/Complainttype")
  Future<List<AllSpinner>> getComplaintType();

  @POST("insert/gate/VisitorInsideStatus")
  Future<dynamic> updateWaitingStatus(@Query("visitor_id") int visitorId);



  
}
