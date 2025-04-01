import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/app/app.dart';

import 'core/observer/bloc_observer.dart';
import 'di/di.dart' as di;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/presentation/screens/home.dart';
import 'package:greon/presentation/screens/login.dart';
import 'package:provider/provider.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  await di.init();

  await Firebase.initializeApp();

  Bloc.observer = MyBlocObserver();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}



