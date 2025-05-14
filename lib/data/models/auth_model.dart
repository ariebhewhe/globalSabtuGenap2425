import 'package:firebase_auth/firebase_auth.dart';

import 'package:jamal/data/models/user_model.dart';

class AuthModel {
  final User? user;
  final UserModel? userModel;

  AuthModel({this.user, this.userModel});

  AuthModel copyWith({User? user, UserModel? userModel}) {
    return AuthModel(
      user: user ?? this.user,
      userModel: userModel ?? this.userModel,
    );
  }
}
