import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/poll_request.dart';
import 'package:society_app/domain/usecase/polls_usecase.dart';

// Polls state
class PollsState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

// Polls list
  final AsyncValue<List<PollRequest>> getSocietyPolls;

// Vote operations: insert/update/delete
  final AsyncValue<dynamic> voteInsert;

// Fetch votes for a specific poll
  final AsyncValue<dynamic> pollVotes;

  const PollsState({
    this.isLoading = false,
    this.data,
    this.error,
    this.getSocietyPolls = const AsyncValue.loading(),
    this.voteInsert = const AsyncValue.data(null),
    this.pollVotes = const AsyncValue.data(null),
  });

  PollsState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<PollRequest>>? getSocietyPolls,
    AsyncValue<dynamic>? voteInsert,
    AsyncValue<dynamic>? pollVotes,
  }) {
    return PollsState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      getSocietyPolls: getSocietyPolls ?? this.getSocietyPolls,
      voteInsert: voteInsert ?? this.voteInsert,
      pollVotes: pollVotes ?? this.pollVotes,
    );
  }

  @override
  List<Object?> get props => [isLoading, data, error, getSocietyPolls, voteInsert, pollVotes];
}

// Polls viewmodel
class PollsViewmodel extends StateNotifier<PollsState> {
  final PollsUsecase useCase;

  PollsViewmodel(this.useCase) : super(const PollsState());

// ✅ Get all society polls
  Future<void> getSocietyPolls(int userId, String societyId,int audience) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final polls = await useCase.getSocietyPolls(userId, societyId,audience);
      state = state.copyWith(
        isLoading: false,
        getSocietyPolls: AsyncValue.data(polls),
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorMessageMapper.map(e),
        getSocietyPolls: AsyncValue.error(e, st),
      );
    }
  }

  // ✅ Insert new vote
  Future<void> addPollVote(int pollId, Map<String, dynamic> body) async {
    state = state.copyWith(voteInsert: const AsyncValue.loading());
    try {
    final result=  await useCase.addPollVote(pollId, body);
      state = state.copyWith(isLoading:false, data: result);
    } catch (e, st) {
      state = state.copyWith(voteInsert: AsyncValue.error(e, st));
    }
  }


// ✅ Update existing vote
Future<void> updatePollVote(int votingId, Map<String, dynamic> body) async {
  state = state.copyWith(voteInsert: const AsyncValue.loading());
  try {
    // Call your useCase to update vote
    final result = await useCase.updatePollVote(votingId, body);
    // If backend returns something null, you can handle it
    if (result == null) {
      throw Exception("Backend returned null for updatePollVote");
    }
    // Update state
    state = state.copyWith(
      isLoading: false,
      data: result,
      voteInsert: AsyncValue.data(result),
    );

    return result;
  } catch (e, st) {
    state = state.copyWith(voteInsert: AsyncValue.error(e, st));
    return;
  }
}


  /// ✅ Delete vote
  Future<void> deletePollVote(int votingId,int userId) async {
    state = state.copyWith(voteInsert: const AsyncValue.loading());
    try {
      await useCase.deletePollVote(votingId,userId);
      state = state.copyWith(voteInsert: const AsyncValue.data("deleted"));
    } catch (e, st) {
      state = state.copyWith(voteInsert: AsyncValue.error(e, st));
    }
  }

}
