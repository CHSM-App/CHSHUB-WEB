import 'package:json_annotation/json_annotation.dart';

part 'login_data.g.dart';

@JsonSerializable()
class LoginData {
  @JsonKey(name: 'staff_id')
  final int? staffId;

  final String? name;

  @JsonKey(name: 'last_name')
  final String? lastName;

  final String? address;

  @JsonKey(name: 'contact_no')
  final String? contactNo;

  final String? email;

  @JsonKey(name: 'date_of_join')
  final String? dateOfJoin;

  @JsonKey(name: 'Role')
  final String? role;

  final String? image;

  @JsonKey(name: 'society_id')
  final String? societyId;

  @JsonKey(name: 'build_id')
  final int? buildId;

  @JsonKey(name: 'build_name')
  final String? buildName;
   @JsonKey(name: 'society_name')
  final String? societyName;
  @JsonKey(name: 'token')
  final String? token;

  LoginData({
     this.staffId,
     this.name,
     this.lastName,
     this.address,
     this.contactNo,
     this.email,
     this.dateOfJoin,
     this.role,
     this.image,
     this.societyId,
     this.buildId,
     this.buildName,
     this.societyName,
     this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) =>
      _$LoginDataFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDataToJson(this);
}
