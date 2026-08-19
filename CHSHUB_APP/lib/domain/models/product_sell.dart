import 'package:json_annotation/json_annotation.dart';

part 'product_sell.g.dart';

@JsonSerializable()
class ProductSell {
  @JsonKey(name: 'available_quantity')
  final String? availableQuantity;

  final String? description;
  final String? price;

  @JsonKey(name: 'product_id')
  final int productId;

  @JsonKey(name: 'image_path')
  final String? imagePath;

  @JsonKey(name: 'product_name')
  final String? productName;

  @JsonKey(name: 'society_id')
  final String? societyId;

  final String? status;
  final String? warranty;

  @JsonKey(name: 'owner_id')
  final int? oId;

  @JsonKey(name: 'contact_no')
  final String? contactNo;

  @JsonKey(name: 'owner_name')
  final String? ownerName;

  @JsonKey(name: 'posted_date')
  final String? postedDate;

  final String? type;

  final int? availability;

  ProductSell({
    this.availableQuantity,
    this.description,
    this.type,
    this.price,
    required this.productId,
    this.imagePath,
    this.productName,
    this.societyId,
    this.status,
    this.warranty,
    this.oId,
    this.contactNo,
    this.ownerName,
    this.postedDate,
    this.availability,
  });

  factory ProductSell.fromJson(Map<String, dynamic> json) =>
      _$ProductSellFromJson(json);

  Map<String, dynamic> toJson() => _$ProductSellToJson(this);
}
