
import 'dart:io';


import '../models/basicinfo.dart';

abstract class BasicInfoRepository {
  Future<List<BasicInfo>> checkPhoneNumber(String preMob);
  Future<List<BasicInfo>> checkUser(String preMob);

  Future<List<BasicInfo>> getBasicInfo(String preMob, int fId,int OwnerId);
  Future<BasicInfo> getProfileEdit(String preMob, int oId, String dob, String type);
  Future<BasicInfo> getGenderEdit(String preMob, int oId, String gender, String type);

  Future<BasicInfo> getEmailEdit(String preMob, int oId, String email, String type);
  Future<BasicInfo> getMobileNoEdit(int oId, String preMob, String type);

  Future<BasicInfo> updateSetting(int oId, String mobile, String type, int phone, int email, int gate);
  Future<BasicInfo> updateHomeNo(String preMob, int fId, String homeNo);
  Future<List<BasicInfo>> fetchHomeNo(String preMob, int fId);

  Future<BasicInfo> deactivateAccount(int oId, String type);
  Future<List<BasicInfo>> getProfile(String preMob, int flatId);
  Future<dynamic> updateProfile(BasicInfo basicInfo);
  Future<dynamic> addProfileImage(File image, String ownerId,String loginType);
  Future<dynamic> deleteProfileImage(String ownerId,String loginType);
  Future<dynamic> addOwnerDocuments(File documents, int flatId, String documentName);
  Future<List<BasicInfo>> ownerDocumentsList(int fId);
   Future<dynamic> deleteDocuments(int documentId);
}
