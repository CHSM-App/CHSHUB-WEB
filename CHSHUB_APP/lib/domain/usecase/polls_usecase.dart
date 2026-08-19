import 'package:society_app/domain/models/poll_request.dart';
import 'package:society_app/domain/repository/polls_repository.dart';

class PollsUsecase {
  final PollsRepository pollsRepository;

  PollsUsecase({required this.pollsRepository});

  Future<List<PollRequest>> getSocietyPolls(int userId, String societyId,int audience) async {
    return await pollsRepository.getSocietyPolls(userId, societyId,audience);
  }

  Future<dynamic> addPollVote(int pollId, Map<String, dynamic> body) async {
    return await pollsRepository.addPollVote(pollId, body);
  }

   Future<dynamic> updatePollVote(int votingId, Map<String, dynamic> body) async {
    return await pollsRepository.updatePollVote(votingId, body);
  }
  Future<dynamic> deletePollVote(int votingId,int userId) async {
  return await pollsRepository.deletePollVote(votingId,userId);
}
}
