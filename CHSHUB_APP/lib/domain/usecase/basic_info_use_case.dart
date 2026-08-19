
import 'dart:io';


import '../models/basicinfo.dart';
import '../repository/basic_info_repository.dart';

class BasicInfoUseCases {
  final BasicInfoRepository repository;

  BasicInfoUseCases(this.repository);

  // Check Phone Number
  Future<List<BasicInfo>> checkPhoneNumber(String preMob) {
    return repository.checkPhoneNumber(preMob);
  }

  Future<List<BasicInfo>> checkUser(String preMob) {
    return repository.checkUser(preMob);
  }

  // Get Basic Info
  Future<List<BasicInfo>> getBasicInfo(String preMob, int fId,int OwnerId) {
    return repository.getBasicInfo(preMob, fId,OwnerId);
  }

  Future<BasicInfo> updateSetting({
    required int oId,
    required String mobile,
    required String type,
    required int phone,
    required int email,
    required int gate,
  }) {
    return repository.updateSetting(oId, mobile, type, phone, email, gate);
  }

  // Update Home Number
  Future<BasicInfo> updateHomeNo(String preMob, int fId, String homeNo) {
    return repository.updateHomeNo(preMob, fId, homeNo);
  }

  // Fetch Home Number
  Future<List<BasicInfo>> fetchHomeNo(String preMob, int fId) {
    return repository.fetchHomeNo(preMob, fId);
  }

  // Deactivate Account
  Future<BasicInfo> deactivateAccount(int oId, String type) {
    return repository.deactivateAccount(oId, type);
  }

  Future<List<BasicInfo>> getProfile(String preMob, int flatId) {
    return repository.getProfile(preMob, flatId);
  }

  Future<dynamic> updateProfile(BasicInfo basicInfo) {
    return repository.updateProfile(basicInfo);
  }
  Future<dynamic> addProfileImage(File image, String ownerId,String loginType) {
    return repository.addProfileImage(image, ownerId,loginType);
  }
  Future<dynamic> deleteProfileImage(String ownerId,String loginType) {
    return repository.deleteProfileImage(ownerId,loginType);
  }
  Future<dynamic> addOwnerDocuments(File documents, int flatId, String documentName) {
    return repository.addOwnerDocuments(documents, flatId, documentName);
  }
   Future<List<BasicInfo>> ownerDocumentsList(int fId) {
    return repository.ownerDocumentsList(fId);
  }
   Future<dynamic> deleteDocuments(int documentId) {
    return repository.deleteDocuments(documentId);
  }
}
