import 'dart:convert';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

import '../google_api_keys.dart';

import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/auth.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;
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

  String get selectedProductId {
    return _selProductId;
  }

  int get selectedProductIndex {
    return _products
        .indexWhere((Product product) => product.id == _selProductId);
  }

  Product get selectedProduct {
    if (_selProductId == null) {
      return null;
    }
    return _products
        .firstWhere((Product product) => product.id == _selProductId);
  }

  bool get showFavorites {
    return _showFavorites;
  }

  Future<bool> addProduct({
    String title,
    String description,
    String image,
    double price,
  }) async {
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
    try {
      http.Response resp = await http.post(
          'https://flutter-products-ba1d6.firebaseio.com/products.json',
          body: json.encode(productData));
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        print(resp.body);
        _isLoading = false;
        notifyListeners();
        return false;
      }
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
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct() {
    final String deletedProductId = selectedProduct.id;
    _isLoading = true;
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();
    return http
        .delete(
            'https://flutter-products-ba1d6.firebaseio.com/products/$deletedProductId.json')
        .then((http.Response response) {
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<Null> fetchProducts({bool onlyForUser = false}) {
    _isLoading = true;
    notifyListeners();
    return http
        .get('https://flutter-products-ba1d6.firebaseio.com/products.json')
        .then<Null>((http.Response resp) {
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
            userId: productData['userId'],
            isFavorite: productData['wishlistUsers'] && (productData['wishlistUsers'] as Map<String, dynamic>)
                .containsKey(_authenticatedUser.id),
          );
          productsList.add(newProduct);
        });
        if (onlyForUser) {
          _products = productsList.where((Product product) => product.userId == _authenticatedUser.id).toList();
        } else {
          _products = productsList;
        }
        _isLoading = false;
        notifyListeners();
      }
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> updateProduct({
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
      _products[selectedProductIndex] = newProduct;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void toggleProductFavoriteStatus() async {
    final bool isCurrentlyFavorite = selectedProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;

    // Update local product
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
    _products[selectedProductIndex] = updatedProduct;
    notifyListeners();

    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put(
        'https://flutter-products-ba1d6.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json',
        body: json.encode(true),
      );
    } else {
      response = await http.delete(
          'https://flutter-products-ba1d6.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      // Update local product
      final Product updatedProduct = Product(
        id: selectedProduct.id,
        title: selectedProduct.title,
        description: selectedProduct.description,
        price: selectedProduct.price,
        image: selectedProduct.image,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        isFavorite: !newFavoriteStatus,
      );
      _products[selectedProductIndex] = updatedProduct;
      _selProductId = null;
      notifyListeners();
    }
    _selProductId = null;
  }

  void selectProduct(String productId) {
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

mixin UsersModel on ConnectedProductsModel {
  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password
    };
    http.Response response;

    if (mode == AuthMode.Login) {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=${googleApiKeys["firebase"]}',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=${googleApiKeys["firebase"]}',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Something went wrong.';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication succeeded!';
      _authenticatedUser = User(
        id: responseData['localId'],
        email: email,
        token: responseData['idToken'],
      );
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      _userSubject.add(true);
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'This password is incorrect.';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email already exists.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    if (token != null) {
      final String email = prefs.getString('userEmail');
      final String id = prefs.getString('userId');
      _authenticatedUser = User(
        email: email,
        id: id,
        token: token,
      );
      _userSubject.add(true);
      notifyListeners();
    }
  }

  void logout() async {
    _authenticatedUser = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
    _userSubject.add(false);
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}
