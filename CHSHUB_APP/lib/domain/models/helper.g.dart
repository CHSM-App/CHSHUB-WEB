// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'helper.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Helper _$HelperFromJson(Map<String, dynamic> json) => Helper(
      workId: (json['helper_work_id'] as num?)?.toInt(),
      flatId: (json['flat_id'] as num?)?.toInt(),
      reviewId: (json['review_id'] as num?)?.toInt(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      usefullContactId: (json['usefull_contact_id'] as num?)?.toInt(),
      pName: json['p_name'] as String?,
      pTypeName: json['p_type_name'] as String?,
      contactNo: json['contact_no'] as String?,
      reviewCount: (json['review_count'] as num?)?.toInt(),
      workCount: (json['work_count'] as num?)?.toInt(),
      orgname: json['org_name'] as String?,
      contactaddress: json['contact_address'] as String?,
      helperId: (json['helper_id'] as num?)?.toInt(),
      unit: json['Unit'] as String?,
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((e) => HelperReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      ownerId: (json['owner_id'] as num?)?.toInt(),
      maidId: (json['maid_id'] as num?)?.toInt(),
      memberId: (json['member_id'] as num?)?.toInt(),
      societyId: json['society_id'] as String?,
      comment: json['review'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      owner: json['owner'] as String?,
      date: json['date'] as String?,
      serventId: (json['servent_id'] as num?)?.toInt(),
      pTypeId: (json['p_type_id'] as num?)?.toInt(),
      societyName: json['name'] as String?,
    );

Map<String, dynamic> _$HelperToJson(Helper instance) => <String, dynamic>{
      'usefull_contact_id': instance.usefullContactId,
      'p_name': instance.pName,
      'p_type_id': instance.pTypeId,
      'p_type_name': instance.pTypeName,
      'contact_no': instance.contactNo,
      'review_count': instance.reviewCount,
      'work_count': instance.workCount,
      'org_name': instance.orgname,
      'contact_address': instance.contactaddress,
      'helper_id': instance.helperId,
      'Unit': instance.unit,
      'reviews': instance.reviews,
      'owner_id': instance.ownerId,
      'flat_id': instance.flatId,
      'maid_id': instance.maidId,
      'member_id': instance.memberId,
      'society_id': instance.societyId,
      'servent_id': instance.serventId,
      'review': instance.comment,
      'rating': instance.rating,
      'owner': instance.owner,
      'date': instance.date,
      'avg_rating': instance.avgRating,
      'review_id': instance.reviewId,
      'helper_work_id': instance.workId,
      'name': instance.societyName,
    };

HelperReview _$HelperReviewFromJson(Map<String, dynamic> json) => HelperReview(
      comment: json['review'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      owner: json['owner'] as String?,
      date: json['date'] as String?,
    );

Map<String, dynamic> _$HelperReviewToJson(HelperReview instance) =>
    <String, dynamic>{
      'review': instance.comment,
      'rating': instance.rating,
      'owner': instance.owner,
      'date': instance.date,
    };
