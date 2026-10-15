import 'package:dropline/features/auth/presentation/pages/loginpage.dart';
import 'package:dropline/features/dashboard/presentation/pages/dashboard_page.dart';

import 'package:dropline/features/event/domain/entities/location_node.dart';
import 'package:dropline/features/event/domain/repositories/location_repository.dart';
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

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const String splash = '/splash';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
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
        path: addEvent,
        name: 'addEvent',
        builder: (context, state) => const AddEventPage(),
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
        path: mainAreas,
        name: 'mainAreas',
        builder: (context, state) {
          return BlocProvider(
            create: (context) =>
                MainAreaCubit(context.read<LocationRepository>())..loadAreas(),
            child: const MainAreaPage(),
          );
        },
      ),

      GoRoute(
        path: subAreas,
        name: 'subAreas',
        builder: (context, state) {
          final area = state.extra;

          if (area is! LocationNode || area.level != LocationLevel.mainArea) {
            return const Scaffold(
              body: Center(child: Text('Main Area not found')),
            );
          }

          return BlocProvider(
            create: (context) => SubAreaCubit(
              repository: context.read<LocationRepository>(),
              mainAreaId: area.id,
            )..loadSubAreas(),
            child: SubAreaPage(mainArea: area),
          );
        },
      ),

      GoRoute(
        path: locations,
        name: 'locations',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is! Map ||
              extra['mainArea'] is! LocationNode ||
              extra['subArea'] is! LocationNode) {
            return const Scaffold(
              body: Center(child: Text('Location information not found')),
            );
          }

          final mainArea = extra['mainArea'] as LocationNode;
          final subArea = extra['subArea'] as LocationNode;

          if (mainArea.level != LocationLevel.mainArea ||
              subArea.level != LocationLevel.subArea ||
              subArea.parentId != mainArea.id) {
            return const Scaffold(
              body: Center(child: Text('Invalid location hierarchy')),
            );
          }

          return BlocProvider(
            create: (context) => LocationListCubit(
              repository: context.read<LocationRepository>(),
              subAreaId: subArea.id,
            )..loadLocations(),
            child: LocationListPage(mainArea: mainArea, subArea: subArea),
          );
        },
      ),

      GoRoute(
        path: specificLocations,
        name: 'specificLocations',
        builder: (context, state) {
          final extra = state.extra;

          if (extra is! Map ||
              extra['mainArea'] is! LocationNode ||
              extra['subArea'] is! LocationNode ||
              extra['location'] is! LocationNode) {
            return const Scaffold(
              body: Center(
                child: Text('Specific Location information not found'),
              ),
            );
          }

          final mainArea = extra['mainArea'] as LocationNode;
          final subArea = extra['subArea'] as LocationNode;
          final location = extra['location'] as LocationNode;

          // Validate complete hierarchy.
          if (mainArea.level != LocationLevel.mainArea ||
              subArea.level != LocationLevel.subArea ||
              location.level != LocationLevel.location ||
              subArea.parentId != mainArea.id ||
              location.parentId != subArea.id) {
            return const Scaffold(
              body: Center(child: Text('Invalid location hierarchy')),
            );
          }

          return BlocProvider(
            create: (context) => SpecificLocationCubit(
              repository: context.read<LocationRepository>(),
              locationId: location.id,
            )..loadSpecificLocations(),
            child: SpecificLocationPage(
              mainArea: mainArea,
              subArea: subArea,
              location: location,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRouter.selectLocation,
        name: 'selectLocation',
        builder: (context, state) {
          return BlocProvider(
            create: (context) => SelectLocationCubit(
              repository: context.read<LocationRepository>(),
            )..loadMainAreas(),
            child: const SelectLocationPage(),
          );
        },
      ),
    ],
  );
}
