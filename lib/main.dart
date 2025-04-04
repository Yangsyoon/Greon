import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get_storage/get_storage.dart';

import 'core/app/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/observer/bloc_observer.dart';
import 'data/data_sources/remote/product_remote_data_source.dart';
import 'di/di.dart' as di;
import 'di/product.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  di.sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  await di.init();
  registerProductFeature();

  Bloc.observer = MyBlocObserver();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(Phoenix(child: const MyApp()));
}
