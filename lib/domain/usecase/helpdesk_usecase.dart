import 'dart:io';

import 'package:society_app/domain/models/all_spinner.dart';
import 'package:society_app/domain/models/helpdesk.dart';
import 'package:society_app/domain/models/helpdesk_comment.dart';
import 'package:society_app/domain/repository/helpdesk_repository.dart';

class HelpdeskUsecase {
  final HelpdeskRepository repository;

  HelpdeskUsecase(this.repository);

  Future<List<HelpdeskComment>> getComments(int id) {
    return repository.getComments(id);
  }

  Future<List<HelpdeskRequest>> getHelpdeskList(String societyID,int ownerID){
    return repository.getHelpdeskList(societyID,ownerID);
  }

  Future<List<HelpdeskRequest>> getRequestById(int id) {
    return repository.getRequestById(id);
  }

  Future<dynamic> insertComments(HelpdeskComment comment) {
    return repository.insertComments(comment);
  }

  Future<dynamic> insertHelpdesk(HelpdeskRequest helpDesk) {
    return repository.insertHelpdesk(helpDesk);
  }

  Future<List<HelpdeskRequest>> getHelpdeskListByHelpdeskID(int helpDeskID) {
    return repository.getHelpdeskListByHelpdeskID(helpDeskID);


  }   
  Future<List<HelpdeskComment>> getHelpdeskComments(int helpDeskID) {
    return repository.getHelpdeskComments(helpDeskID);
  }
  Future<dynamic> updateRequest(int status, int commentID,int helpdesk) {
    return repository.updateRequest(status, commentID, helpdesk);
  }

  Future<List<AllSpinner>> getAllComplainTypes() {
    return repository.getAllComplainTypes();
  }

  Future<dynamic> addHelpdeskImages(File image, String helpdeskID) {
    return repository.addHelpdeskImages(image, helpdeskID);
  }
  
  Future<List<AllSpinner>> getComplaintType() {
    return repository.getComplaintType();
  }

  
}
