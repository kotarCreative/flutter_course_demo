import 'package:flutter/material.dart';

class Product {
  final String title;
  final String description;
  final String image;
  final double price;
  final String userEmail;
  final String userId;
  final bool isFavorite;

  Product(
      {@required this.title,
      @required this.description,
      @required this.image,
      @required this.price,
      @required this.userEmail,
      @required this.userId,
      this.isFavorite = false});
}
