import 'package:society_app/domain/models/helper.dart';
import 'package:society_app/domain/repository/helper_repository.dart';

import '../api/api_service.dart';

class HelperRepositoryImpl implements HelperRepository {
  final ApiService apiService;

  HelperRepositoryImpl(this.apiService);

  @override
  Future<List<Helper>> getHelperList(String society) {
   return apiService.getHelperList(society);
  }
  
  @override
  Future<Helper> deleteHelperReview(int reviewId) {
   return apiService.deleteHelperReview(reviewId);
  }

  @override
  Future<List<Helper>> getHelperDetails(String society) {
   return apiService.getHelperDetails(society);
  }
  @override
  Future<List<Helper>> FindHelperDetails(int helperId, String type) {
   return apiService.FindHelperDetails(helperId, type);
  }
  @override
  Future<List<Helper>> FindHelperInfo(int helperId, String type) {
   return apiService.FindHelperInfo(helperId, type);
  }
  @override
  Future<List<Helper>> HelperReview(int helperId, String type) {
   return apiService.HelperReview(helperId, type);
  }
  
  @override
  Future<dynamic> addReview(Helper helper) {
    return apiService.addReview(helper);
  }
   @override
  Future<dynamic> helperAssignFlat(Helper helper) {
    return apiService.helperAssignFlat(helper);
  }
   @override
  Future<Helper> unAssignflat(int usefullContactId,int workId,int flatId){
   return apiService.unAssignflat(usefullContactId,workId,flatId);
  }
    @override
  Future<Helper> flatunAssign(int workId){
   return apiService.flatunAssign(workId);
  }
}
