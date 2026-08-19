import 'package:society_app/domain/models/poll_request.dart';

abstract class PollsRepository {
  Future<List<PollRequest>> getSocietyPolls(int userId, String societyId,int audience);

  Future<dynamic> addPollVote(int pollId, Map<String, dynamic> body);

    Future<dynamic> updatePollVote(int votingId, Map<String, dynamic> body);

     Future<dynamic> deletePollVote(int votingId,int userId);


}
