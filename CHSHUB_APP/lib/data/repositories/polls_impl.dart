import 'package:dio/dio.dart';
import 'package:society_app/data/api/api_service.dart';
import 'package:society_app/domain/models/poll_request.dart';
import 'package:society_app/domain/repository/polls_repository.dart';

class PollsImpl implements PollsRepository {
  final ApiService apiService;

  PollsImpl(this.apiService);
@override
Future<List<PollRequest>> getSocietyPolls(int userId, String societyId, int audience) async {
  try {
    final response = await apiService.getPolls(userId, societyId, audience);
    List<dynamic> pollsJson;

    if (response is List) {
      pollsJson = response;
    } else if (response is Map<String, dynamic>) {
      final responseMap = response;

      if (responseMap.containsKey('data') && responseMap['data'] is List) {
        pollsJson = responseMap['data'] as List;
      } else if (responseMap.containsKey('polls') && responseMap['polls'] is List) {
        pollsJson = responseMap['polls'] as List;
      
      } else if (responseMap.containsKey('items') && responseMap['items'] is List) {
        pollsJson = responseMap['items'] as List;
       
      } else if (responseMap.containsKey('results') && responseMap['results'] is List) {
        pollsJson = responseMap['results'] as List;
       
      } else {
        pollsJson = [responseMap];
        
      }
    } else {
      throw Exception('Unexpected response format: ${response.runtimeType}');
    }

    final polls = <PollRequest>[];
    for (int i = 0; i < pollsJson.length; i++) {
      final json = pollsJson[i];
      try {
        if (json is Map<String, dynamic>) {
          final poll = PollRequest.fromJson(json);
          polls.add(poll);
        
        } else {
          print('Skipped non-Map JSON at index $i: $json');
        }
      } catch (e) {
        print('Error parsing poll at index $i: $e');
      }
    }

    return polls;
  } on DioException catch (dioError) {
    String errorMessage = 'Network error';
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        errorMessage = 'Server error: ${dioError.response?.statusCode}';
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Unknown error: ${dioError.message}';
        break;
      default:
        errorMessage = 'Network error: ${dioError.message}';
    }
    throw Exception(errorMessage);
  } catch (e) {
    throw Exception('Failed to load polls: $e');
  }
}

@override
Future<dynamic> addPollVote(int pollId, Map<String, dynamic> body) async {
  try {
    final response = await apiService.addPollVote(pollId, body);
    return response;
  } catch (e) {
    throw Exception("Failed to vote: $e");
  }
}


@override
Future<dynamic> updatePollVote(int votingId, Map<String, dynamic> body) async {
  try {
    final response = await apiService.updatePollVote(votingId, body);
    return response;
  } catch (e) {
    throw Exception("Failed to update vote: $e");
  }
}
@override
  Future<void> deletePollVote(int votingId,int userId) async {
  try {
    final response = await apiService.deleteVotes(votingId,userId);
  } catch (e) {
    rethrow;
  }
}




}

