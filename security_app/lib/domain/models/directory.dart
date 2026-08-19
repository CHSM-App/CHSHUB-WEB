import 'package:json_annotation/json_annotation.dart';

part 'directory.g.dart';

@JsonSerializable()
class Directory {
  final int id;
  final String? name;
  final String? contact;
  final String email;

  @JsonKey(name: 'Unit')
  final String unit;

  Directory({
    required this.id,
    this.name,
    this.contact,
    required this.email,
    required this.unit,
  });

  factory Directory.fromJson(Map<String, dynamic> json) =>
      _$DirectoryFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoryToJson(this);
}
