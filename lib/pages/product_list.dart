import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'product_edit.dart';
import '../scoped_models/main.dart';
import '../models/product.dart';

class ProductListPage extends StatefulWidget {
  final MainModel model;

  ProductListPage(this.model);

  @override State<StatefulWidget> createState() {
    return _ProductListPageState();
  }
}


class _ProductListPageState extends State<ProductListPage> {

  @override void initState() {
    widget.model.fetchProducts();
    super.initState();
  }

  Widget _buildEditButton(
    BuildContext context,
    int index,
    MainModel model,
  ) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () {
        model.selectProduct(model.allProducts[index].id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return ProductEditPage();
            },
          ),
        ).then((_) {
          model.selectProduct(null);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (
        BuildContext context,
        Widget child,
        MainModel model,
      ) {
        final List<Product> products = model.allProducts;
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            final Product product = model.allProducts[index];
            return Dismissible(
              key: Key(product.title),
              background: Container(color: Colors.red),
              onDismissed: (DismissDirection direction) {
                if (direction == DismissDirection.endToStart) {
                  model.selectProduct(product.id);
                  model.deleteProduct();
                } else if (direction == DismissDirection.startToEnd) {
                  print('startToEnd');
                } else {
                  print('other swiping');
                }
              },
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(product.image),
                    ),
                    title: Text(product.title),
                    subtitle: Text('\$${product.price}'),
                    trailing: _buildEditButton(context, index, model),
                  ),
                  Divider()
                ],
              ),
            );
          },
          itemCount: products.length,
        );
      },
    );
  }
}
