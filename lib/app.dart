
import 'package:dropline/core/di/global_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';

import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Dashboard BLoC
        BlocProvider<DashboardBloc>(
          create: (context) => sl<DashboardBloc>()..add(const GetProjectList()),
        ),

        // Add other BLoCs here
      ],
      child: MaterialApp.router(
        title: 'Dropline',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
