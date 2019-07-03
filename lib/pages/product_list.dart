import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import 'product_edit.dart';
import '../scoped_models/main.dart';
import '../models/product.dart';

class ProductListPage extends StatelessWidget {
  ProductListPage();

  Widget _buildEditButton(
    BuildContext context,
    int index,
    MainModel model,
  ) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () {
        model.selectProduct(index);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return ProductEditPage();
            },
          ),
        );
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
        final List<Product> products = model.products;
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              key: Key(products[index].title),
              background: Container(color: Colors.red),
              onDismissed: (DismissDirection direction) {
                if (direction == DismissDirection.endToStart) {
                  model.selectProduct(index);
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
                      backgroundImage: AssetImage(products[index].image),
                    ),
                    title: Text(products[index].title),
                    subtitle: Text('\$${products[index].price}'),
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
