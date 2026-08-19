
import 'dart:io';

import 'package:society_app/data/api/api_service.dart';

import '../../domain/models/product_sell.dart';
import '../../domain/repository/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiService apiService;

  ProductRepositoryImpl(this.apiService);

  @override
  Future<dynamic> addProduct(ProductSell product) {
    return apiService.addProduct(product);
  }

    @override
  Future<List<ProductSell>> productList(String societyId) {
    return apiService.productList(societyId);
  }

 @override
  Future<List<ProductSell>> ownerProductList(String societyId, int ownerId) {
    return apiService.ownerProductList(societyId, ownerId);
  }

  @override
  Future deleteProduct(int productId) {
    return  apiService.deleteProduct(productId);
  }
  
  @override
  Future  addProductImages(File image, String productId) {
    return apiService.addProductImages(image, productId);
  }
@override
Future<List<ProductSell>> viewProduct(int productId) {
    return apiService.viewProduct(productId);
  }
   @override
  Future<dynamic> updateProduct(ProductSell productsell) {
    return apiService.updateProduct(productsell);
  }


}