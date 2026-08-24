import 'package:json_annotation/json_annotation.dart';

import 'json_utils.dart';

part 'user.g.dart';

/// The signed-in user, exactly as backend/web/lib/publicUser.js exposes them.
/// Returned by /auth/login, /auth/refresh and /auth/me.
@JsonSerializable()
class User {
  @JsonKey(name: 'user_id', fromJson: asInt)
  final int? userId;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'username')
  final String? username;

  @JsonKey(name: 'user_type_id', fromJson: asInt)
  final int? userTypeId;

  @JsonKey(name: 'user_type')
  final String? userType;

  @JsonKey(name: 'society_id', fromJson: asString)
  final String? societyId;

  @JsonKey(name: 'society_name')
  final String? societyName;

  @JsonKey(name: 'village_id', fromJson: asString)
  final String? villageId;

  @JsonKey(name: 'village_name')
  final String? villageName;

  /// 'Society' or 'Village'.
  @JsonKey(name: 'tenant_type')
  final String? tenantType;

  @JsonKey(name: 'owner_id', fromJson: asInt)
  final int? ownerId;

  @JsonKey(name: 'email')
  final String? email;

  @JsonKey(name: 'contact_no', fromJson: asString)
  final String? contactNo;

  const User({
    this.userId,
    this.name,
    this.username,
    this.userTypeId,
    this.userType,
    this.societyId,
    this.societyName,
    this.villageId,
    this.villageName,
    this.tenantType,
    this.ownerId,
    this.email,
    this.contactNo,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
