import 'package:scoped_model/scoped_model.dart';

import './products.dart';
import './users.dart';

class MainModel extends Model with ProductsModel, UsersModel {

}