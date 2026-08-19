// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PollRequest _$PollRequestFromJson(Map<String, dynamic> json) => PollRequest(
      pollId: (json['PollId'] as num?)?.toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      userVoteId: (json['Voting_Id'] as num?)?.toInt(),
      topic: json['Topic'] as String?,
      description: json['Description'] as String?,
      expiryDate: json['ExpiryDate'] as String?,
      allowMultipleVotes: (json['AllowMultipleVotes'] as num?)?.toInt(),
      oneVotePerUnit: (json['OneVotePerUnit'] as num?)?.toInt(),
      audience: json['Audience'] as String?,
      expireDate: json['Expiredate'] as String?,
      societyId: json['society_id'] as String?,
      totalVotes: (json['total_votes'] as num?)?.toInt(),
      options: (json['options'] as List<dynamic>)
          .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PollRequestToJson(PollRequest instance) =>
    <String, dynamic>{
      'PollId': instance.pollId,
      'user_id': instance.userId,
      'Voting_Id': instance.userVoteId,
      'Topic': instance.topic,
      'Description': instance.description,
      'ExpiryDate': instance.expiryDate,
      'AllowMultipleVotes': instance.allowMultipleVotes,
      'OneVotePerUnit': instance.oneVotePerUnit,
      'Audience': instance.audience,
      'Expiredate': instance.expireDate,
      'society_id': instance.societyId,
      'total_votes': instance.totalVotes,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };

PollOption _$PollOptionFromJson(Map<String, dynamic> json) => PollOption(
      optionId: json['OptionId'] as String?,
      text: json['text'] as String?,
      votes: (json['votes'] as num?)?.toInt(),
      userVoteId: json['voting_Id'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
      isDisabled: json['isDisabled'] as bool? ?? false,
    )..isProcessing = json['isProcessing'] as bool;

Map<String, dynamic> _$PollOptionToJson(PollOption instance) =>
    <String, dynamic>{
      'OptionId': instance.optionId,
      'text': instance.text,
      'votes': instance.votes,
      'voting_Id': instance.userVoteId,
      'isSelected': instance.isSelected,
      'isDisabled': instance.isDisabled,
      'isProcessing': instance.isProcessing,
    };
