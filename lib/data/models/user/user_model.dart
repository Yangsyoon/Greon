import 'dart:convert';

import '../../../domain/entities/user/app_user.dart';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel extends AppUser {
  const UserModel({
    required String id,
    required String fullName,
    required String email,
  }) : super(
    id: id,
    fullName: fullName,
    email: email,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json["_id"],
    fullName: json["fullName"],
    email: json["email"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "fullName": fullName,
    "email": email,
  };
}
