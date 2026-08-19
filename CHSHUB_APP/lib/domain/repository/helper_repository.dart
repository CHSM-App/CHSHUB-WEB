import '../models/helper.dart';

abstract class HelperRepository {
  Future<List<Helper>> getHelperList(String society);
   Future<List<Helper>> getHelperDetails(String society );
  Future<List<Helper>> FindHelperDetails(int helperId, String type);
  Future<List<Helper>> FindHelperInfo(int helperId, String type);
  Future<List<Helper>> HelperReview(int helperId, String type);
    Future<dynamic> addReview(Helper helper);
  Future<Helper> deleteHelperReview(int reviewId);
    Future<dynamic> helperAssignFlat(Helper helper);
      Future<Helper> unAssignflat(int usefullContactId,int workId,int flatId);
      Future<Helper> flatunAssign(int workId);
}

