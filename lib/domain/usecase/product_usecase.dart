
import 'dart:io';


import '../models/product_sell.dart';
import '../repository/product_repository.dart';

class ProductUseCase {
  final ProductRepository repository;

  ProductUseCase(this.repository);

  Future<dynamic> addProductImages(File image, String productId) {
    return repository.addProductImages(image, productId);
  }
  Future< dynamic> addProduct(ProductSell product) {
    return repository.addProduct(product);
  }
  Future<List<ProductSell>> productList(String societyId) {
    return repository.productList(societyId);
  }
  Future<List<ProductSell>> ownerProductList(String societyId, int ownerId) {
    return repository.ownerProductList(societyId, ownerId);
  }

  Future<dynamic> deleteProduct(int productId) {
    return repository.deleteProduct(productId);
  }

  Future<List<ProductSell>> viewProduct(int productId) async {
    return await repository.viewProduct(productId);
  }
  
  Future<dynamic> updateProduct(ProductSell productsell) {
    return repository.updateProduct(productsell);
  }
}