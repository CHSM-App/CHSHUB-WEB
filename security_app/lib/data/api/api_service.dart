import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:security_app/core/constant.dart';
import 'package:security_app/domain/models/alert_notification.dart';
import 'package:security_app/domain/models/emergency_alert.dart';
import 'package:security_app/domain/models/login_data.dart';
import 'package:security_app/domain/models/directory.dart';
import 'package:security_app/domain/models/notification.dart';
import 'package:security_app/domain/models/staff_attendance.dart';
import 'package:security_app/domain/models/staffs.dart';
import 'package:security_app/domain/models/token_response.dart';
import 'package:security_app/domain/models/unit_spinner.dart';
import 'package:security_app/domain/models/visitors.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: baseUrl) // <-- replace with your base URL
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  @GET("/")
  Future<HttpResponse> checkHealth();
  // Step 1 of login: ask the server to generate and SMS a code to this number.
  @POST("login/otp/request")
  Future<dynamic> requestOtp(@Body() Map<String, dynamic> body);

  // Step 2: exchange the code for tokens. The body must carry `otp`.
  @POST("login/CreateLogin")
  Future<TokenResponse> createLogin(@Body() TokenResponse tokenResponse);

  @POST("login/refreshAccessToken")
  Future<TokenResponse> refreshAccessToken(@Body() TokenResponse tokenResponse);

  @POST("insert/gate/updateToken")
  Future<dynamic> updateToken(
    @Query("staff_id") int staffId,
    @Query("token") String token,
  );
  // Login
  @GET("login/GateKeeper/checkUser/")
  Future<List<LoginData>> checkUser(@Query("contact") String contact);

  @GET("data/GetLoginData/{contact}")
  Future<List<LoginData>> getLoginDetails(@Path("contact") String contact);

  @FormUrlEncoded()
  @POST("insert/gate/UpdateGatekeeper1/{id}")
  Future<LoginData> updateGateKeeper1(
    @Path("id") int id,
    @Field("contact_no") String contactNo,
    @Field("name") String name,
    @Field("email") String email,
    @Field("address") String address,
    @Field("image") String image,
  );

  @POST("insert/gate/updateGateKeeper/{staff_id}")
  Future<dynamic> updateGatekeeper(
    @Path("staff_id") int staffId,
    @Body() LoginData loginData,
  );

  // Visitors
  @GET("data/getVisitorList")
  Future<List<Visitors>> getVisitorList(@Query("SocietyId") String SocietyId);

  @GET("data/getVisitorHistory")
  Future<List<Visitors>> getVisitorHistory(
    @Query("SocietyId") String SocietyId,
    @Query("startDate") String startDate,
    @Query("endDate") String endDate,
  );

  @GET("data/getRegularVisitor")
  Future<List<Visitors>> getRegularVisitor(
    @Query("SocietyId") String SocietyId,
  );

  @POST("insert/gate/visitor")
  Future<Visitors> insertVisitor(@Body() Visitors visitors);

  @FormUrlEncoded()
  @POST("insert/gate/updateVisitor")
  Future<Visitors> updateVisitor(
    @Field("v_id") int vId,
    @Field("action") String action,
    @Field("user_id") int userId,
  );

  // Emergency & Directory
  @GET("users/more/EmergencyContacts")
  Future<List<Directory>> getEmergencyContacts();

  @GET("data/directory/Residence/{b_id}")
  Future<List<Directory>> getNeighbours(@Path("b_id") int bId);

  @GET("users/more/Committee/{society_id}")
  Future<List<Directory>> getCommitteeMembers(
    @Path("society_id") String societyId,
  );

  @GET("data/Spinner/unit/{society_id}")
  Future<List<UnitSpinner>> getAllUnits(@Path("society_id") String societyId);

  @POST("insert/gate/AddEmergencyAlert")
  Future<dynamic> AddEmergencyAlert(@Body() EmergencyAlert emergencyAlert);

  @MultiPart()
  @POST("upload/VisitorProfile")
  Future<dynamic> addVisitorProfile(
    @Part(name: "image") File image,
    @Part(name: "visitor_id") int visitorId,
  );
  // Staff
  @GET("data/staffList/{b_id}")
  Future<List<Staffs>> getStaffList(@Path("b_id") int bId);

  @GET("data/staffExitList/{b_id}")
  Future<List<Staffs>> getStaffExit(@Path("b_id") int bId);

  @POST('insert/gate/AddVisitor/Guest')
  Future<dynamic> addGuest(
    @Query("flat_id") int flatId,
    @Query("v_name") String visitorName,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("purpose") String purpose,
    @Query("society_id") String societyId,
    @Query("location") String location,
  );

  @POST('insert/gate/AddVisitor/Cab')
  Future<dynamic> addCab(
    @Query("flat_id") int flatId,
    @Query("v_name") String cabName,
    @Query("vehical_no") String vehicleNo,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("company") String company,
    @Query("society_id") String societyId,
    @Query("location") String location,
  );

  @POST('insert/gate/AddVisitor/Service')
  Future<dynamic> addService(
    @Query("flat_id") int flatId,
    @Query("v_name") String serviceName,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("company") String company,
    @Query("vehical_no") String vehicleNo,
    @Query("society_id") String societyId,
  );

  @POST('insert/gate/AddVisitor/Delivery')
  Future<dynamic> addDelivery(
    @Query("flat_id") int flatId,
    @Query("v_name") String deliveryName,
    @Query("pre_date") String predate,
    @Query("contact_no") String contactNo,
    @Query("purpose") String purpose,
    @Query("vehical_no") String vehicleNo,
    @Query("company") String company,
    @Query("society_id") String societyId,
  );
  @FormUrlEncoded()
  @POST("insert/gate/StaffEntry")
  Future<Staffs> updateStaff(
    @Field("staff_id") int staffId,
    @Field("action") String action,
    @Field("b_id") int bId,
    @Field("user_id") int userId,
  );
  @MultiPart()
  @POST("upload/StaffProfile")
  Future<dynamic> staffProfile(
    @Part(name: "image") File image,
    @Part(name: "staff_id") int staffId,
  );

  @POST("notify/send-notifications")
  Future<dynamic> sendMessage(@Body() SendNotification body);

  @GET("data/getTokens/{society}/{type}")
  Future<List<LoginData>> getAllTokens(
    @Path("society") String society,
    @Path("type") String type,
  );

  @POST("notify/send-datamessage")
  Future<dynamic> sendDataMessage(@Body() SendNotification body);

  @POST("insert/DeleteStaffPhoto")
  Future<dynamic> deleteStaffImage(@Field("staff_id") String staffId);

  @POST("notify/gatekeeperapp/Insert/NewToken")
  Future<dynamic> insertToken(
    @Query("staff_id") int ownerId,
    @Query("token") String token,
  );

  @POST("insert/gate/VisitorInsideStatus")
  Future<dynamic> updateInsideStatus(@Query("visitor_id") int visitorId);

  @POST("insert/gate/VisitorWaitingStatus")
  Future<dynamic> updateWaitingStatus(@Query("visitor_id") int visitorId);

  // Smart Staff Attendance - EntryExit
  @FormUrlEncoded()
  @POST("insert/gate/StaffAttendance/EntryExit")
  Future<dynamic> staffEntryExit(
    @Field("staff_id") int staffId,
    @Field("status") int statusFlag,
  );

  @POST("insert/gate/update/attendance")
  Future<dynamic> updateAttendance(@Body() StaffAttendance body);

  @GET("data/StaffAttendance/status/{staff_id}")
  Future<List<StaffAttendance>> getStaffAttendanceStatus(
    @Path("staff_id") int staffId,
  );

  @GET("data/StaffAttendance/status/{staff_id}")
  Future<dynamic> getCurrentStaffAttendanceStatus(
    @Path("staff_id") int staffId,
  );

  @GET("data/StaffAttendance/{staff_id}")
  Future<dynamic> getMyAttendanceHistory(
    @Path("staff_id") int staffId,
  );

  @GET("data/GetEmergencyAlertPreference/{society_id}/{alert_type}")
  Future<dynamic> getEmergencyAlertPreference(
    @Path("society_id") String societyId,
    @Path("alert_type") String alertType,
  );

  @GET("data/GetActiveAlerts")
  Future<List<EmergencyAlert>> getActiveAlerts();

  @GET("data/buildingList/{society_id}")
  Future<List<LoginData>> buildingListFetch(
    @Path("society_id") String societyId,
  );

  @GET("data/attendance/today/{society_id}")
  Future<List<StaffAttendance>> getStaffAttendance(
    @Path("society_id") String society_id,
  );

  @POST("insert/gate/EmergencyAlert/CustomMessage")
  Future<dynamic> addCustomMessage(@Body() EmergencyAlert emergencyAlert);

  @POST("notify/send-alert-notifications")
  Future<dynamic> sendAlertNotifications(@Body() AlertNotification body);

  @POST("insert/gate/updatePreVisitorStatus")
  Future<dynamic> updatePreVisitor(
    @Query("visitor_id") int? visitor_id,
    @Query("guest_name") String guestName,
    @Query("contact_no") String contactNo,
    @Query("entry_type") String entryType,
  );


  @GET("data/committeeContact/{society_id}")
  Future<List<Visitors>> getContacts(
    @Path("society_id") String society_id,
  );

  
}
