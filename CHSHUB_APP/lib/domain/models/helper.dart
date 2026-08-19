import 'package:json_annotation/json_annotation.dart';

part 'helper.g.dart';

@JsonSerializable()
class Helper {
  @JsonKey(name: "usefull_contact_id")
  final int? usefullContactId;
  @JsonKey(name: "p_name")
  final String? pName;
    @JsonKey(name: "p_type_id")
  final int? pTypeId;
  @JsonKey(name: "p_type_name")
  final String? pTypeName;
  @JsonKey(name: "contact_no")
  final String? contactNo;
  @JsonKey(name: "review_count")
  final int? reviewCount;
  @JsonKey(name: "work_count")
  final int? workCount;
  @JsonKey(name: "org_name")
  final String? orgname;
  @JsonKey(name: "contact_address")
  final String? contactaddress;
  @JsonKey(name: "helper_id")
  final int? helperId;
  @JsonKey(name: "Unit")
  final String? unit;
  @JsonKey(name: "reviews")
  final List<HelperReview>? reviews;
  @JsonKey(name: "owner_id")
  final int? ownerId;
  @JsonKey(name: "flat_id")
  final int? flatId;
  @JsonKey(name: "maid_id")
  final int? maidId;
  @JsonKey(name: "member_id")
  final int? memberId;
  @JsonKey(name: "society_id")
  final String? societyId;
  @JsonKey(name: "servent_id")
  final int? serventId;
    @JsonKey(name: "review")
  final String? comment;
  @JsonKey(name: "rating")
  final double? rating;
  @JsonKey(name: "owner")
  final String? owner;
  @JsonKey(name: "date")
  final String? date;
  @JsonKey(name: "avg_rating")
  final double? avgRating;

  @JsonKey(name:"review_id")
  final int? reviewId;

  @JsonKey(name:"helper_work_id")
  final int? workId;
 @JsonKey(name: "name")
  final String? societyName;
  Helper({
    this.workId,
    this.flatId,
    this.reviewId,
    this.avgRating,
    this.usefullContactId,
    this.pName,
    this.pTypeName,
    this.contactNo,
    this.reviewCount,
    this.workCount,
    this.orgname,
    this.contactaddress,
    this.helperId,
    this.unit,
    this.reviews,
    this.ownerId,
    this.maidId,
    this.memberId,
    this.societyId,
    this.comment,
    this.rating,
    this.owner,
    this.date,
    this.serventId,
    this.pTypeId,
    this.societyName,
  });

  factory Helper.fromJson(Map<String, dynamic> json) => _$HelperFromJson(json);

  Map<String, dynamic> toJson() => _$HelperToJson(this);

  Helper copyWith({int? reviewCount, double? avgRating}) {
    return Helper(
      workId: workId,
      flatId: flatId,
      reviewId: reviewId,
      avgRating: avgRating ?? this.avgRating,
      usefullContactId: usefullContactId,
      pName: pName,
      pTypeName: pTypeName,
      contactNo: contactNo,
      reviewCount: reviewCount ?? this.reviewCount,
      workCount: workCount,
      orgname: orgname,
      contactaddress: contactaddress,
      helperId: helperId,
      unit: unit,
      reviews: reviews,
      ownerId: ownerId,
      maidId: maidId,
      memberId: memberId,
      societyId: societyId,
      comment: comment,
      rating: rating,
      owner: owner,
      date: date,
      serventId: serventId,
      pTypeId: pTypeId,
      societyName: societyName,
    );
  }
}

@JsonSerializable()
class HelperReview {
  @JsonKey(name: "review")
  final String? comment;
  @JsonKey(name: "rating")
  final double? rating;
  @JsonKey(name: "owner")
  final String? owner;
  @JsonKey(name: "date")
  final String? date;

  HelperReview({
    this.comment,
    this.rating,
    this.owner,
    this.date,
  });

  factory HelperReview.fromJson(Map<String, dynamic> json) => _$HelperReviewFromJson(json);

  Map<String, dynamic> toJson() => _$HelperReviewToJson(this);
}