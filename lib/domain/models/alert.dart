import 'package:json_annotation/json_annotation.dart';
part 'alert.g.dart';


@JsonSerializable()
class Alert {
  @JsonKey(name: "r_id")
  final int? RId;
    @JsonKey(name: "flat_id")
  final int? flatId;
    @JsonKey(name: "message")
  final String? Message; 
   @JsonKey(name: "type")
  final String? Type;
  @JsonKey(name: 'society_id')
  final String? SocietyId;
  @JsonKey(name: 'message_sub')
  final String? Messagesub;
  @JsonKey(name: 'owner_id')
  final int? OwnerId;
  @JsonKey(name: 'owner_type')
  final int? Ownertype;
   @JsonKey(name: "security_id")
  final int? securityId;
  

  Alert ({
    this.RId,
    this.flatId,
    this.Message,
    this.Type,
    this.SocietyId,
    this.Messagesub,
    this.OwnerId,
    this.Ownertype,
    this.securityId,
    
    
  });

    factory Alert.fromJson(Map<String, dynamic> json) {
    return _$AlertFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$AlertToJson(this);
  }

}


