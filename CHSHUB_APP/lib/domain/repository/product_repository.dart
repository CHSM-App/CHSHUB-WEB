import 'dart:io';


import '../models/product_sell.dart';

abstract class ProductRepository {

  Future<dynamic> addProduct(ProductSell product);
   Future<dynamic> addProductImages(File image, String productId);
  Future<List<ProductSell>> productList(String societyId);
  Future<List<ProductSell>> ownerProductList(String societyId, int ownerId);
  Future<dynamic> deleteProduct(int productId);
   Future<List<ProductSell>> viewProduct( int productId);
     Future<dynamic> updateProduct(ProductSell productsell);
}