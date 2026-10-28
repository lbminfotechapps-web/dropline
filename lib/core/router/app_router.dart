import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/features/me/presentation/me.dart';
import 'package:dropline/features/auth/presentation/pages/loginpage.dart';
import 'package:dropline/features/auth/presentation/pages/choose_option.dart';
import 'package:dropline/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dropline/features/event/domain/entities/location_flow_args.dart';

import 'package:dropline/features/event/domain/entities/location_node.dart';
import 'package:dropline/features/event/domain/repositories/location_repository.dart';
import 'package:dropline/features/event/domain/repositories/location_repository_factory.dart';
import 'package:dropline/features/event/domain/repositories/location_selection_repository.dart';
import 'package:dropline/features/event/presentation/cubit/location_list_cubit.dart';
import 'package:dropline/features/event/presentation/cubit/main_area_cubit.dart';
import 'package:dropline/features/event/presentation/cubit/select_location_cubit.dart';
import 'package:dropline/features/event/presentation/cubit/specific_location_cubit.dart';
import 'package:dropline/features/event/presentation/cubit/sub_area_cubit.dart'
    show SubAreaCubit;
import 'package:dropline/features/event/presentation/pages/add_event.dart';
import 'package:dropline/features/event/presentation/pages/location_list_page.dart';
import 'package:dropline/features/event/presentation/pages/main_area_page.dart';
import 'package:dropline/features/event/presentation/pages/select_location_page.dart';
import 'package:dropline/features/event/presentation/pages/specific_location_page.dart';
import 'package:dropline/features/event/presentation/pages/sub_area_page.dart';

import 'package:dropline/features/punch/presentation/pages/punch_out.dart';

import 'package:dropline/features/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Widget locationRouteError() {
  return const Scaffold(
    body: Center(child: Text('Event location information not found')),
  );
}

Widget provideLocationRepository({
  required LocationFlowArgs args,
  required Widget child,
}) {
  final repository = sl<LocationRepositoryFactory>().forScope(args.scope);

  return RepositoryProvider<LocationRepository>.value(
    value: repository,
    child: child,
  );
}

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const String splash = '/splash';
  static const String login = '/login';
  static const String chooseOption = '/choose-option';
  static const String dashboard = '/dashboard';
  static const String me = '/me';
  static const String addEvent = '/add-event';
  static const String punchOut = '/punchOut';
  static const String mainAreas = '/mainAreas';
  static const String subAreas = '/subAreas';
  static const String locations = '/locations';
  static const String specificLocations = '/specificLocations';
  static const String selectLocation = '/selectLocation';
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splash,

    routes: [
      GoRoute(
        path: me,
        builder: (context, state) =>
            MePage(onStartWork: () => context.push(dashboard)),
      ),
      GoRoute(
        path: chooseOption,
        builder: (context, state) => const ChooseOptionPage(),
      ),
      GoRoute(
        path: AppRouter.addEvent,
        name: 'addEvent',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};

          return AddEventPage(
            projectId: extra['projectId']?.toString() ?? '',
            projectName: extra['projectName']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) {
          return const DashboardPage();
        },
      ),

      GoRoute(
        path: punchOut,
        name: 'punchOut',
        builder: (context, state) => const PunchOutPage(),
      ),

      GoRoute(
        path: AppRouter.mainAreas,
        name: 'mainAreas',
        builder: (context, state) {
          final args = state.extra;

          if (args is! LocationFlowArgs) {
            return locationRouteError();
          }

          return provideLocationRepository(
            args: args,
            child: BlocProvider(
              create: (context) =>
                  MainAreaCubit(context.read<LocationRepository>())
                    ..loadAreas(),
              child: MainAreaPage(flowArgs: args),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRouter.subAreas,
        name: 'subAreas',
        builder: (context, state) {
          final args = state.extra;

          if (args is! LocationFlowArgs ||
              args.mainArea == null ||
              args.mainArea!.level != LocationLevel.mainArea) {
            return locationRouteError();
          }

          return provideLocationRepository(
            args: args,
            child: BlocProvider(
              create: (context) => SubAreaCubit(
                repository: context.read<LocationRepository>(),
                mainAreaId: args.mainArea!.id,
              )..loadSubAreas(),
              child: SubAreaPage(mainArea: args.mainArea!, flowArgs: args),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRouter.locations,
        name: 'locations',
        builder: (context, state) {
          final args = state.extra;

          if (args is! LocationFlowArgs ||
              args.mainArea == null ||
              args.subArea == null ||
              args.mainArea!.level != LocationLevel.mainArea ||
              args.subArea!.level != LocationLevel.subArea ||
              args.subArea!.parentId != args.mainArea!.id) {
            return locationRouteError();
          }

          return provideLocationRepository(
            args: args,
            child: BlocProvider(
              create: (context) => LocationListCubit(
                repository: context.read<LocationRepository>(),
                subAreaId: args.subArea!.id,
              )..loadLocations(),
              child: LocationListPage(
                mainArea: args.mainArea!,
                subArea: args.subArea!,
                flowArgs: args,
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRouter.specificLocations,
        name: 'specificLocations',
        builder: (context, state) {
          final args = state.extra;

          if (args is! LocationFlowArgs ||
              args.mainArea == null ||
              args.subArea == null ||
              args.location == null ||
              args.mainArea!.level != LocationLevel.mainArea ||
              args.subArea!.level != LocationLevel.subArea ||
              args.location!.level != LocationLevel.location ||
              args.subArea!.parentId != args.mainArea!.id ||
              args.location!.parentId != args.subArea!.id) {
            return locationRouteError();
          }

          return provideLocationRepository(
            args: args,
            child: BlocProvider(
              create: (context) => SpecificLocationCubit(
                repository: context.read<LocationRepository>(),
                locationId: args.location!.id,
              )..loadSpecificLocations(),
              child: SpecificLocationPage(
                mainArea: args.mainArea!,
                subArea: args.subArea!,
                location: args.location!,
                flowArgs: args,
              ),
            ),
          );
        },
      ),

      GoRoute(
        path: AppRouter.selectLocation,
        name: 'selectLocation',
        builder: (context, state) {
          final args = state.extra;

          if (args is! LocationFlowArgs) {
            return locationRouteError();
          }

          return provideLocationRepository(
            args: args,
            child: BlocProvider(
              create: (context) => SelectLocationCubit(
                repository: context.read<LocationRepository>(),
                selectionRepository: sl<LocationSelectionRepository>(),
                scope: args.scope,
              )..loadMainAreas(),
              child: SelectLocationPage(flowArgs: args),
            ),
          );
        },
      ),
    ],
  );
}
