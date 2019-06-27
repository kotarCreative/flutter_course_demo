import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../scoped_models/products.dart';
import '../models/product.dart';

class ProductEditPage extends StatefulWidget {
  ProductEditPage();

  @override
  State<StatefulWidget> createState() {
    return _ProductEditPageState();
  }
}

class _ProductEditPageState extends State<ProductEditPage> {
  final Map<String, dynamic> _formData = {
    'title': null,
    'description': null,
    'price': null,
    'image': 'assets/food.jpg'
  };
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Widget _buildTitleTextField(Product product) {
    return TextFormField(
        decoration: InputDecoration(labelText: 'Product Title'),
        initialValue: product == null ? '' : product.title,
        validator: (String value) {
          if (value.isEmpty || value.length < 5) {
            return 'Title is required and should be 5+ characters long.';
          }
        },
        onSaved: (String value) {
          _formData['title'] = value;
        });
  }

  Widget _buildDescriptionTextField(Product product) {
    return TextFormField(
        decoration: InputDecoration(labelText: 'Product Description'),
        initialValue: product == null ? '' : product.description,
        validator: (String value) {
          if (value.isEmpty || value.length < 10) {
            return 'Description is required and should be 10+ characters long.';
          }
        },
        maxLines: 5,
        onSaved: (String value) {
          _formData['description'] = value;
        });
  }

  Widget _buildPriceTextField(Product product) {
    return TextFormField(
        decoration: InputDecoration(labelText: 'Product Price'),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        initialValue:
            product == null ? '' : product.price.toString(),
        validator: (String value) {
          if (value.isEmpty ||
              !RegExp(r'^(?:[1-9]\d*|0)?(?:\.\d+)?$').hasMatch(value)) {
            return 'Price is required and should be a number.';
          }
        },
        onSaved: (String value) {
          _formData['price'] = double.parse(value);
        });
  }

  void _submitForm(Function addProduct, Function updateProduct, [int productIndex]) {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    Product _newProduct = Product(
        title: _formData['title'],
        description: _formData['description'],
        price: _formData['price'],
        image: _formData['image']);

      productIndex == null
        ? addProduct(_newProduct)
        : updateProduct(productIndex, _newProduct);
    Navigator.pushReplacementNamed(context, '/products');
  }

  Widget _buildSubmitButton() {
    return ScopedModelDescendant<ProductsModel>(
      builder: (BuildContext context, Widget child, ProductsModel model) {
        return RaisedButton(
            child: Text('Save'),
            textColor: Colors.white,
            onPressed: () => _submitForm(
                  model.addProduct,
                  model.updateProduct,
                  model.selectedProductIndex
                ));
      },
    );
  }

  Widget _buildPageContent(BuildContext context, Product product) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
            children: <Widget>[
              _buildTitleTextField(product),
              _buildDescriptionTextField(product),
              _buildPriceTextField(product),
              SizedBox(
                height: 10.0,
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<ProductsModel>(
      builder: (BuildContext context, Widget child, ProductsModel model) {
        final Widget pageContent = _buildPageContent(context, model.selectedProduct);
        return model.selectedProductIndex == null
            ? pageContent
            : Scaffold(
                appBar: AppBar(
                  title: Text('Edit Product'),
                ),
                body: pageContent,
              );
      },
    );
  }
}