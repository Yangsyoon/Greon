import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:greon/configs/configs.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/user_bloc/user_bloc.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../core/enums/enums.dart';

Widget userLoggedProfileContainer(
    BuildContext context,
    String nickname,
    String email,
    String? imageUrl,
    ) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null ? Icon(Icons.person, size: 28) : null,
          ),
          SizedBox(width: 12),
          Text(
            nickname,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      TextButton(
        onPressed: () async {
          await firebase.FirebaseAuth.instance.signOut();
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.read<UserBloc>().add(SignOutUser());
          context.read<NavigationCubit>().updateTab(NavigationTab.homeTab);
        },
        child: Text("로그아웃", style: TextStyle(color: Colors.red)),
      ),
    ],
  );

}
