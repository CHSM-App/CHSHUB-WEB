import 'package:society_app/domain/repository/helper_repository.dart';

import '../models/helper.dart';

class HelperUseCases {
  final HelperRepository repository;

  HelperUseCases(this.repository);
  Future<List<Helper>> getHelperList(String society){
    return repository.getHelperList(society);
  }
   Future<List<Helper>> getHelperDetails(String society) {
    return repository.getHelperDetails(society);
  }
  Future<List<Helper>> FindHelperDetails(int helperId, String type) {
    return repository.FindHelperDetails(helperId, type);
  }
  Future<List<Helper>> FindHelperInfo(int helperId, String type) {
    return repository.FindHelperInfo(helperId, type);
  }
  Future<List<Helper>> HelperReview(int helperId, String type) {
    return repository.HelperReview(helperId, type);
  }
  
  Future< dynamic> addReview(Helper helper) {
    return repository.addReview(helper);
  }

  Future<Helper> deleteHelperReview(int reviewId) {
    return repository.deleteHelperReview(reviewId);
  } 
    Future<dynamic> helperAssignFlat(Helper helper) {
    return repository.helperAssignFlat(helper);
  }
   Future<Helper> unAssignflat(int usefullContactId,int workId,int flatId) {
    return repository.unAssignflat(usefullContactId,workId,flatId);
  }
   Future<Helper> flatunAssign(int workId) {
    return repository.flatunAssign(workId);
  }
}