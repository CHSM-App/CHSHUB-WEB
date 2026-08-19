import 'package:json_annotation/json_annotation.dart';

part 'directory.g.dart';

@JsonSerializable()
class Directory {
  @JsonKey(name: 'contact_id')
  final int? contactId;

  final String? name;
  final String? contact;
  final String? email;

  @JsonKey(name: 'Unit')
  final String? unit;

  @JsonKey(name: 'mask_phone')
  final int? maskPhone;

  @JsonKey(name: 'mask_email')
  final int? maskEmail;

  @JsonKey(name: 'mem_id')
  final int? memId;

  final String? token;

  @JsonKey(name: 'user_id')
  final int? userId;

  @JsonKey(name: 'web_token')
  final String? webToken;

  Directory({
    required this.contactId,
    this.name,
    this.contact,
    this.email,
     this.unit,
     this.maskPhone,
     this.maskEmail,
     this.memId,
     this.token,
     this.userId,
     this.webToken,
  });

  factory Directory.fromJson(Map<String, dynamic> json) => _$DirectoryFromJson(json);
  Map<String, dynamic> toJson() => _$DirectoryToJson(this);
}
