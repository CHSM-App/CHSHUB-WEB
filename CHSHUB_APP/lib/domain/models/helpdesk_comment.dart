import 'package:json_annotation/json_annotation.dart';

part 'helpdesk_comment.g.dart';

@JsonSerializable()
class HelpdeskComment {

  final String? ownerType;

  @JsonKey(name: "flat_id")
  final int? flatId;

  @JsonKey(name: "owner_id")
  final int? ownerId;

  final int? oExId;

  final int? comment_id;

  final String? name;

  final String? unit;

  final String? description;

  @JsonKey(name: 'dateTime')
  final String? dateTime;

  final String? image;

  @JsonKey(name: 'helpdesk_id')
  final int helpdeskId;

  @JsonKey(name: 'type')
  final String? type;

  HelpdeskComment({
    this.ownerId,
    this.oExId,
    this.name,
    this.unit,
    this.description,
    this.dateTime,
    this.image,
    required this.helpdeskId,
    this.comment_id,
    this.flatId,
    this.ownerType,
    this.type,
  });

  factory HelpdeskComment.fromJson(Map<String, dynamic> json) =>
      _$HelpdeskCommentFromJson(json);

  Map<String, dynamic> toJson() => _$HelpdeskCommentToJson(this);
}
