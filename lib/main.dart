import 'package:dropline/app.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/features/event/data/repositories/in_memory_location_repository.dart';
import 'package:dropline/features/event/domain/repositories/location_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();


    await initGlobalDi();
  runApp(
    RepositoryProvider<LocationRepository>(
      create: (_) => InMemoryLocationRepository(),
      child: const MyApp(),
    ),
  );
}
