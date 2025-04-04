import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/observer/bloc_observer.dart';
import 'data/data_sources/remote/product_remote_data_source.dart';
import 'di/di.dart' as di;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/presentation/screens/home.dart';
import 'package:greon/presentation/screens/login.dart';
import 'package:provider/provider.dart';

import 'di/product.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  di.sl.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await di.init();
  registerProductFeature();

  Bloc.observer = MyBlocObserver();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}
