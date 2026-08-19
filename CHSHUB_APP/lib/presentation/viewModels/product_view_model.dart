// add_product_state.dart


import 'package:society_app/core/network/error_message_mapper.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/product_sell.dart';
import '../../domain/usecase/product_usecase.dart';
@immutable
class ProductState  {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final AsyncValue<List<ProductSell>>? viewProductDetails;
final AsyncValue<List<ProductSell>> productListDetails;
  final AsyncValue<List<ProductSell>> ownerProductListDetails;
   final AsyncValue<ProductSell?> deleteProductDetails;
  const ProductState({
    this.isLoading = false,
    this.data,
    this.error,
    this.productListDetails = const AsyncValue.loading(),
    this.ownerProductListDetails = const AsyncValue.loading(),
    this.deleteProductDetails = const AsyncValue.loading(),
    this.viewProductDetails = const AsyncValue.loading(),
  });

  ProductState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    AsyncValue<List<ProductSell>>? productListDetails,
    AsyncValue<List<ProductSell>>? ownerProductListDetails,
    AsyncValue<ProductSell?>? deleteProductDetails,
    AsyncValue<List<ProductSell>>? viewProductDetails,

  }) {
    return ProductState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      productListDetails: productListDetails ?? this.productListDetails,
      ownerProductListDetails: ownerProductListDetails ?? this.ownerProductListDetails,
      deleteProductDetails: deleteProductDetails ?? this.deleteProductDetails,
      viewProductDetails: viewProductDetails ?? this.viewProductDetails,
    );
  }

  @override
  List<Object?> get props => [isLoading, data, error];
}
class ProductViewModel extends StateNotifier<ProductState> {
  final ProductUseCase addProductUseCase;

  ProductViewModel(this.addProductUseCase) : super(const ProductState());

  Future<void> addProduct(ProductSell product) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await addProductUseCase.addProduct(product);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }
 Future<void> addProductImages(File image, int productId) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
  
    final result = await addProductUseCase.addProductImages(image, productId.toString());

    state = state.copyWith(isLoading: false, data: result);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
  }
}
  Future<void> fetchProductList(String societyId) async {
    state = state.copyWith(productListDetails: const AsyncValue.loading());
    try {
      final result = await addProductUseCase.productList(societyId);
      state = state.copyWith(productListDetails: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(productListDetails: AsyncValue.error(e, st));
    }
  }
  Future<void> fetchOwnerProductList(String societyId, int ownerId) async {
    state = state.copyWith(ownerProductListDetails: const AsyncValue.loading());
    try {
      final result = await addProductUseCase.ownerProductList(societyId, ownerId);
      state = state.copyWith(ownerProductListDetails: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(ownerProductListDetails: AsyncValue.error(e, st));
    }
  }
  Future<void> deleteProduct(int productId) async {
   state = state.copyWith(isLoading: true, error: null);
  try {
  
    final result = await addProductUseCase.deleteProduct( productId);

    state = state.copyWith(isLoading: false, data: result);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
  }
}
  Future<void> viewProduct(int productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await addProductUseCase.viewProduct(productId);
      state = state.copyWith(isLoading: false, viewProductDetails: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(isLoading: false, viewProductDetails: AsyncValue.error(e, st));
    }
  }
    Future<void> updateProduct(ProductSell productsell) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await addProductUseCase.updateProduct(productsell);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

}
