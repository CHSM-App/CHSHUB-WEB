import 'dart:io';

import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/all_spinner.dart';
import 'package:society_app/domain/models/helpdesk.dart';
import 'package:society_app/domain/repository/helpdesk_repository.dart';

import '../../domain/models/helpdesk_comment.dart';

class HelpdeskRepositoryImpl implements HelpdeskRepository {
  final ApiService apiService;

  HelpdeskRepositoryImpl(this.apiService);


  @override
  Future<List<HelpdeskComment>> getComments(int id) {
    return apiService.getComments(id);
  }

  @override
  Future<List<HelpdeskRequest>> getHelpdeskList(String societyID,int ownerID) {
    return apiService.getHelpdeskList(societyID,ownerID);
    
  }

  @override
  Future<List<HelpdeskRequest>> getRequestById(int id) {
    return apiService.getRequestById(id);
  }

  @override
  Future<dynamic> insertComments(HelpdeskComment comment) {
    return apiService.insertComments(comment);
  }

  @override
  Future<dynamic> insertHelpdesk(HelpdeskRequest helpDesk) {
    return apiService.insertHelpdesk(helpDesk);
  }

  @override
  Future<List<HelpdeskRequest>> getHelpdeskListByHelpdeskID(int helpDeskID) {
    return apiService.getRequestById(helpDeskID);
  }
  
  @override
  Future<List<HelpdeskComment>> getHelpdeskComments(int helpDeskID) {
    return apiService.getComments(helpDeskID);
  }

  @override
  Future<dynamic> updateRequest(int status, int commentID, int helpDeskID) {
    return apiService.updateRequest(status, commentID, helpDeskID);
  }

  @override
  Future<List<AllSpinner>> getAllComplainTypes() {
    return apiService.getAllComplainTypes();
  }

//upload  helpdesk image
  @override
  Future<dynamic> addHelpdeskImages(File image, String helpdeskId) {
    return apiService.addHelpdeskImages(image, helpdeskId);
  }
   @override
  Future<List<AllSpinner>> getComplaintType() {
    return apiService.getComplaintType();
  }
  
}
  