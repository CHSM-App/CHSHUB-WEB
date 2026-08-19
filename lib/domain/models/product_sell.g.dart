// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_sell.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSell _$ProductSellFromJson(Map<String, dynamic> json) => ProductSell(
      availableQuantity: json['available_quantity'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      price: json['price'] as String?,
      productId: (json['product_id'] as num).toInt(),
      imagePath: json['image_path'] as String?,
      productName: json['product_name'] as String?,
      societyId: json['society_id'] as String?,
      status: json['status'] as String?,
      warranty: json['warranty'] as String?,
      oId: (json['owner_id'] as num?)?.toInt(),
      contactNo: json['contact_no'] as String?,
      ownerName: json['owner_name'] as String?,
      postedDate: json['posted_date'] as String?,
      availability: (json['availability'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductSellToJson(ProductSell instance) =>
    <String, dynamic>{
      'available_quantity': instance.availableQuantity,
      'description': instance.description,
      'price': instance.price,
      'product_id': instance.productId,
      'image_path': instance.imagePath,
      'product_name': instance.productName,
      'society_id': instance.societyId,
      'status': instance.status,
      'warranty': instance.warranty,
      'owner_id': instance.oId,
      'contact_no': instance.contactNo,
      'owner_name': instance.ownerName,
      'posted_date': instance.postedDate,
      'type': instance.type,
      'availability': instance.availability,
    };
