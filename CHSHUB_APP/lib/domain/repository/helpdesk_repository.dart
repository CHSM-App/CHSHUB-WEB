import 'dart:io';

import 'package:society_app/domain/models/all_spinner.dart';
import 'package:society_app/domain/models/helpdesk.dart';
import 'package:society_app/domain/models/helpdesk_comment.dart';

abstract class HelpdeskRepository {
  Future<List<HelpdeskRequest>> getHelpdeskList(String societyID,int ownerID);
  Future<dynamic> insertHelpdesk(HelpdeskRequest helpDesk);
  Future<List<HelpdeskRequest>> getRequestById(int id);
  Future<List<HelpdeskComment>> getComments(int id);
  Future<dynamic> insertComments(HelpdeskComment comment);
  Future<List<HelpdeskRequest>> getHelpdeskListByHelpdeskID(int helpDeskID);
  Future<List<HelpdeskComment>> getHelpdeskComments(int helpDeskID);
  Future<dynamic> updateRequest(int status, int commentID, int helpdeskID);
  Future<List<AllSpinner>> getAllComplainTypes();
  Future<dynamic> addHelpdeskImages(File image, String helpdeskID);
    Future<List<AllSpinner>> getComplaintType();
}
