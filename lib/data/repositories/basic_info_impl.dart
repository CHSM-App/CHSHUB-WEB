import 'dart:io';

import 'package:society_app/core/storage/token_storage.dart';
import '../../domain/models/basicinfo.dart';
import '../../domain/repository/basic_info_repository.dart';
import '../api/api_service.dart';

class BasicInfoRepositoryImpl implements BasicInfoRepository {
  final ApiService apiService;

  BasicInfoRepositoryImpl(this.apiService);

  @override
  Future<List<BasicInfo>> checkPhoneNumber(String mobile) async {
    return apiService.checkPhoneNumber(mobile);
  }

  @override
  Future<List<BasicInfo>> checkUser(String mobile) {
    return apiService.checkUser(mobile);
  }

  @override
  Future<List<BasicInfo>> getBasicInfo(String preMob, int fId,int ownerID)async {
    final response = await apiService.getBasicInfo(preMob, fId,ownerID);

    if (response.isNotEmpty) {
      // Save values in secure storage
      await TokenStorage.saveValue(
        'owner_mobile',
        response[0].preMob.toString(),
      );
      await TokenStorage.saveValue('owner_id', response[0].ownerId.toString());
      await TokenStorage.saveValue('flat_id', response[0].flatId.toString());
      await TokenStorage.saveValue('society_id', response[0].societyId.toString());
      await TokenStorage.saveValue('owner_name', response[0].name.toString());
      await TokenStorage.saveValue('login_type', response[0].login.toString());
      await TokenStorage.saveValue('owner_email', response[0].email.toString());
      await TokenStorage.saveValue('Unit', response[0].unit.toString());
      await TokenStorage.saveValue('SocietyName',response[0].societyName.toString());
    }
    return response;
  }

  @override
  Future<BasicInfo> getProfileEdit(
    String preMob,
    int oId,
    String dob,
    String type,
  ) {
    return apiService.getProfileEdit(preMob, oId, dob, type);
  }

  @override
  Future<BasicInfo> getGenderEdit(
    String preMob,
    int oId,
    String gender,
    String type,
  ) {
    return apiService.getGenderEdit(preMob, oId, gender, type);
  }

  @override
  Future<BasicInfo> getEmailEdit(
    String preMob,
    int oId,
    String email,
    String type,
  ) {
    return apiService.getEmailEdit(preMob, oId, email, type);
  }

  @override
  Future<BasicInfo> getMobileNoEdit(int oId, String preMob, String type) {
    return apiService.getMobileNoEdit(oId, preMob, type);
  }

  @override
  Future<BasicInfo> updateSetting(
    int oId,
    String mobile,
    String type,
    int phone,
    int email,
    int gate,
  ) {
    return apiService.updateSetting(oId, mobile, type, phone, email, gate);
  }

  @override
  Future<BasicInfo> updateHomeNo(String preMob, int fId, String homeNo) {
    return apiService.updateHomeNo(preMob, fId, homeNo);
  }

  @override
  Future<List<BasicInfo>> getProfile(String preMob, int flatId) {
    return apiService.getProfile(preMob, flatId);
  }

  @override
  Future<List<BasicInfo>> fetchHomeNo(String preMob, int fId) {
    return apiService.fetchHomeNo(preMob, fId);
  }

  @override
  Future<BasicInfo> deactivateAccount(int oId, String type) {
    return apiService.deactivateAccount(oId, type);
  }

  @override
  Future<dynamic> updateProfile(BasicInfo basicInfo) {
    return apiService.updateProfile(basicInfo);
  }

  @override
  Future<dynamic> addProfileImage(File image, String ownerId,String loginType) {
    return apiService.addProfileImage(image, ownerId,loginType);
  }
  @override
  Future<dynamic> deleteProfileImage(String ownerId,String loginType) {
    return apiService.deleteProfileImage(ownerId,loginType);
  }
  @override
  Future<dynamic> addOwnerDocuments(File documents, int flatId, String documentName) {
    return apiService.addOwnerDocuments(documents, flatId, documentName);
  }
   @override
  Future<List<BasicInfo>> ownerDocumentsList(int fId) {
    return apiService.ownerDocumentsList(fId);
  }
  
  
  @override
  Future<dynamic> deleteDocuments(int documentId){
    return apiService.deleteDocuments(documentId);
  }

}
