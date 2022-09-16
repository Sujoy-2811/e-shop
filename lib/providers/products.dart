import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];
  // var _showFavoritesOnly = false;
  final String authToken;
  final String userId;

  Products(this.authToken, this.userId, this._items);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((prodItem) => prodItem.isFavorite).toList();
    // }

    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  // void showFavoritesOnly() {
  //   _showFavoritesOnly = true;
  //   notifyListeners();
  // }

  // void showAll() {
  //   _showFavoritesOnly = false;
  //   notifyListeners();
  // }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://e-shop2811-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    print("fetchh start 47");
    // -check
    // 'https://e-shop2811-default-rtdb.firebaseio.com/products.json/products.json?auth=$authToken&$filterString';
    //-check
    // 'https://flutter-update.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final response = await http.get(Uri.parse(url));
      print("fetch end 54");
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url =
          //-check
          // 'https://flutter-update.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
          'https://e-shop2811-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
      // 'https://e-shop2811-default-rtdb.firebaseio.com/products.json/userFavorites/$userId.json?auth=$authToken';
      final favoriteResponse = await http.get(Uri.parse(url));
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'].toDouble(),
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> addProduct(Product product) async {
    print("add");
    print(product.imageUrl);
    print(product.title);
    print(product.price);
    print(product.description);
    final url =
        // 'https://e-shop2811-default-rtdb.firebaseio.com/products.json/products.json?auth=$authToken';
        // 'https://e-shop2811-default-rtdb.firebaseio.com/products.json/products.json';
        'https://e-shop2811-default-rtdb.firebaseio.com/products.json?auth=$authToken';
    // -check
    // 'https://flutter-update.firebaseio.com/products.json?auth=$authToken';
    print("add product start 97");
    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': userId,
        }),
      );
      print("fetch done 109");
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      print(response.body.toString());
      _items.add(newProduct);
      // _items.insert(0, newProduct); // at the start of the list
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          // 'https://e-shop2811-default-rtdb.firebaseio.com/products.json/products/$id.json?auth=$authToken';
          'https://e-shop2811-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
      // -check
      print("update start");
      // 'https://flutter-update.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(Uri.parse(url),
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('... 144');
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://e-shop2811-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken';
    // -check
    // 'https://flutter-update.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
