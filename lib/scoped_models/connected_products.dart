import 'dart:convert';
import 'dart:async';

import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/user.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  int _selProductIndex;
  User _authenticatedUser;
  bool _isLoading = false;

  Future<Null> addProduct({
    String title,
    String description,
    String image,
    double price,
  }) {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRq-FvZPIBrrtGdyxCA7EDV1vOomV30ZxopXr41aftX5FmM1eoPUA',
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id,
    };
    return http
        .post('https://flutter-products-ba1d6.firebaseio.com/products.json',
            body: json.encode(productData))
        .then((http.Response resp) {
      _isLoading = false;
      final Map<String, dynamic> respData = json.decode(resp.body);
      final Product newProduct = Product(
        id: respData['name'],
        title: title,
        description: description,
        image: image,
        price: price,
        userEmail: _authenticatedUser.email,
        userId: _authenticatedUser.id,
      );
      _products.add(newProduct);
      notifyListeners();
    });
  }
}

mixin ProductsModel on ConnectedProductsModel {
  bool _showFavorites = false;

  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayProducts {
    return _showFavorites
        ? _products.where((Product product) => product.isFavorite).toList()
        : List.from(_products);
  }

  int get selectedProductIndex {
    return _selProductIndex;
  }

  Product get selectedProduct {
    if (_selProductIndex == null) {
      return null;
    }
    return _products[_selProductIndex];
  }

  bool get showFavorites {
    return _showFavorites;
  }

  void deleteProduct() {
    final String deletedProductId = selectedProduct.id;
    _isLoading = true; 
    _products.removeAt(_selProductIndex);
    _selProductIndex = null;
    notifyListeners();
    http
        .delete(
            'https://flutter-products-ba1d6.firebaseio.com/products/${selectedProduct.id}.json')
        .then((http.Response response) {
      _isLoading = false;
      _products.removeAt(_selProductIndex);
      notifyListeners();
    });
  }

  void fetchProducts() {
    _isLoading = true;
    http
        .get('https://flutter-products-ba1d6.firebaseio.com/products.json')
        .then((http.Response resp) {
      _isLoading = false;
      final List<Product> productsList = [];
      final Map<String, dynamic> productsData = json.decode(resp.body);
      if (productsData != null) {
        productsData.forEach((String productId, dynamic productData) {
          final Product newProduct = Product(
              id: productId,
              title: productData['title'],
              description: productData['description'],
              image: productData['image'],
              price: productData['price'],
              userEmail: productData['userEmail'],
              userId: productData['userId']);
          productsList.add(newProduct);
        });
        _products = productsList;
      }
      notifyListeners();
    });
  }

  Future<Null> updateProduct({
    String title,
    String description,
    String image,
    double price,
  }) {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'image': image,
      'image':
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRq-FvZPIBrrtGdyxCA7EDV1vOomV30ZxopXr41aftX5FmM1eoPUA',
      'price': price,
      'userEmail': selectedProduct.userEmail,
      'userId': selectedProduct.userId,
    };

    return http
        .put(
            'https://flutter-products-ba1d6.firebaseio.com/products/${selectedProduct.id}.json',
            body: json.encode(productData))
        .then((http.Response response) {
      _isLoading = false;
      final Product newProduct = Product(
        id: selectedProduct.id,
        title: title,
        description: description,
        image: image,
        price: price,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
      );
      _products[_selProductIndex] = newProduct;
      notifyListeners();
    });
  }

  void toggleProductFavoriteStatus() {
    final bool isCurrentlyFavorite = selectedProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    final Product updatedProduct = Product(
      id: selectedProduct.id,
      title: selectedProduct.title,
      description: selectedProduct.description,
      price: selectedProduct.price,
      image: selectedProduct.image,
      userEmail: selectedProduct.userEmail,
      userId: selectedProduct.userId,
      isFavorite: newFavoriteStatus,
    );
    _products[_selProductIndex] = updatedProduct;
    _selProductIndex = null;
    notifyListeners();
  }

  void selectProduct(int index) {
    _selProductIndex = index;
    if (index != null) {
      notifyListeners();
    }
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

mixin UsersModel on ConnectedProductsModel {
  void login(String email, String password) {
    _authenticatedUser = User(
      id: 'fafafea',
      email: email,
      password: password,
    );
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}
