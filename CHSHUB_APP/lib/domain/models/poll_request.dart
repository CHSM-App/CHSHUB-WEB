import 'package:json_annotation/json_annotation.dart';

part 'poll_request.g.dart';

@JsonSerializable(explicitToJson: true)
class PollRequest {
  @JsonKey(name: 'PollId')
  final int? pollId;

  @JsonKey(name: 'user_id')
  final int? userId;

@JsonKey(name: 'Voting_Id') 
  final int? userVoteId;


  @JsonKey(name: 'Topic')
  final String? topic;

  @JsonKey(name: 'Description')
  final String? description;

  @JsonKey(name: 'ExpiryDate')
  final String? expiryDate;

  @JsonKey(name: 'AllowMultipleVotes')
  final int? allowMultipleVotes;

  @JsonKey(name: 'OneVotePerUnit')
  final int? oneVotePerUnit;

  @JsonKey(name: 'Audience')
  final String? audience;

  @JsonKey(name: 'Expiredate')
  final String? expireDate;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'total_votes')
  final int? totalVotes;

  @JsonKey(name: 'options')
  final List<PollOption> options;

  PollRequest({
    required this.pollId,
    required this.userId,
     required this.userVoteId,
    required this.topic,
    required this.description,
    required this.expiryDate,
    required this.allowMultipleVotes,
    required this.oneVotePerUnit,
    required this.audience,
    required this.expireDate,
    required this.societyId,
    required this.totalVotes,
    required this.options,
  });

  factory PollRequest.fromJson(Map<String, dynamic> json) =>
      _$PollRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PollRequestToJson(this);
}

@JsonSerializable()
class PollOption {
  @JsonKey(name: 'OptionId')
  final String? optionId;

  @JsonKey(name: 'text')
  final String? text;

  @JsonKey(name: 'votes')
  final int? votes;

  // @JsonKey(name: 'Voting_Id')  
  // int? userVoteId;
  @JsonKey(name: 'voting_Id')
  final String? userVoteId; // keep as string for multiple ids

  @JsonKey(name: 'isSelected', defaultValue: false)
  bool isSelected;

  @JsonKey(name: 'isDisabled', defaultValue: false)
  bool isDisabled;
    bool isProcessing = false;

  PollOption({
    required this.optionId,
    required this.text,
    required this.votes,
      this.userVoteId,
    this.isSelected = false, 
    this.isDisabled=false,
  });

// factory PollOption.fromJson(Map<String, dynamic> json) {
//     return PollOption(
//       optionId: json['OptionId']?.toString(),
//       text: json['text']?.toString(),
//       votes: json['votes'] ?? 0,
//       userVoteId: json['Voting_Id'],
//       isSelected: json['isSelected'] ?? false,
//       isDisabled: json['isDisabled'] ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() => _$PollOptionToJson(this);
  
  
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      optionId: json['OptionId']?.toString(),
      text: json['text']?.toString(),
      votes: json['votes'] ?? 0,
      userVoteId: json['voting_Id']?.toString() ?? '',
      isSelected: json['isSelected'] ?? false,
      isDisabled: json['isDisabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$PollOptionToJson(this);

  /// Helper to get voting IDs as List<int>
  List<int> getVotingIdList() {
    if (userVoteId == null || userVoteId!.isEmpty) return [];
    return userVoteId!
        .split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList();
  }
}
