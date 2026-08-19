import 'package:json_annotation/json_annotation.dart';

part 'basicinfo.g.dart';

@JsonSerializable()
class BasicInfo {
  final String? name;
  @JsonKey(name: 'owner_id')
  final int? ownerId;
  
  final String? login;
  @JsonKey(name: 'society_id')
  final String? societyId;
  final String? type;
  @JsonKey(name: 'flat_no')
  final String? flatNo;
  @JsonKey(name: 'pre_mob')
  final String? preMob;
  final String? email;
  @JsonKey(name: 'Unit')
  final String? unit;
    @JsonKey(name: 'profile_image')
  final String? profileImage;
  @JsonKey(name: 'sq_ft')
  final String? sqFt;
  final String? dob;
  @JsonKey(name: 'job_title')
  final String? jobTitle;
  @JsonKey(name: 'flat_id')
  final int? flatId;
  @JsonKey(name: 'build_id')
  final int? buildId;
  @JsonKey(name: 'wing_id')
  final int? wingId;
  final String? gender;
  final String? language;
  @JsonKey(name: 'mask_phone')
  final int? maskPhone;
  @JsonKey(name: 'mask_email')
  final int? maskEmail;
  @JsonKey(name: 'share_gate')
  final String? shareGate;
  @JsonKey(name: 'home_no')
  final String? homeNo;
  @JsonKey(name: 'society_name')
  final String? societyName;
  @JsonKey(name: 'build_name')
  final String? buildName;
  @JsonKey(name: 'build_address')
  final String? buildAddress;
  @JsonKey(name: 'login_status')
  final int? loginStatus;
  final String? token;
  @JsonKey(name: 'active_status')
  final int? activeStatus;
  @JsonKey(name: 'app_notify')
  final int? appNotify;
  @JsonKey(name: 'call_notify')
  final int? callNotify;

  @JsonKey(name:'contact_no')
  final String? contactNo;
  
  @JsonKey(name:'relation')
  final String? relation;

  @JsonKey(name:'docs_path')
  final String? documents;

    @JsonKey(name:'doc_name')
  final String? documentName;


    @JsonKey(name:'upload_date')
  final String? uploadDate;
  
    @JsonKey(name:'doc_type')
  final String? docType;

  @JsonKey(name:'doc_path')
  final String? docPath;

    @JsonKey(name: 'document_id')
  final int? documentId;



  BasicInfo({
    this.contactNo,
     this.name,
     this.ownerId,
     this.login,
     this.societyId,
     this.type,
     this.flatNo,
     this.preMob,
     this.relation,
     this.email,
     this.unit,
     this.sqFt,
     this.dob,
     this.jobTitle,
     this.flatId,
     this.buildId,
     this.wingId,
     this.gender,
     this.profileImage,
     this.language,
     this.maskPhone,
     this.maskEmail,
      this.shareGate,
     this.homeNo,
     this.societyName,
     this.buildName,
     this.buildAddress,
     this.loginStatus,
     this.token,
     this.activeStatus,
     this.appNotify,
     this.callNotify,
     this.documents,
     this.documentName,
     this.uploadDate,
     this.docType,
     this.docPath,
     this.documentId
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) =>
      _$BasicInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BasicInfoToJson(this);
}


