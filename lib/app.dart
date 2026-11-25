import 'package:dropline/core/di/global_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';

import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeController = AppThemeController();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ThemeData(
      fontFamily: AppTextStyles.fontFamily,
      textTheme: TextTheme(
        displayLarge: const TextStyle(fontWeight: FontWeight.w500),
        displayMedium: const TextStyle(fontWeight: FontWeight.w500),
        displaySmall: const TextStyle(fontWeight: FontWeight.w500),
        headlineLarge: const TextStyle(fontWeight: FontWeight.w500),
        headlineMedium: const TextStyle(fontWeight: FontWeight.w500),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w500),
        titleLarge: const TextStyle(fontWeight: FontWeight.w500),
        titleMedium: const TextStyle(fontWeight: FontWeight.w500),
        titleSmall: const TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w500),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w500),
        bodySmall: const TextStyle(fontWeight: FontWeight.w500),
        labelLarge: const TextStyle(fontWeight: FontWeight.w500),
        labelMedium: const TextStyle(fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(fontWeight: FontWeight.w500),
      ).apply(fontFamily: AppTextStyles.fontFamily),
    );
    final whiteTheme = currentTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: WhiteAppTheme.accent)
          .copyWith(
            primary: WhiteAppTheme.accent,
            surface: WhiteAppTheme.background,
            onSurface: WhiteAppTheme.foreground,
          ),
      scaffoldBackgroundColor: WhiteAppTheme.background,
      extensions: const [WhiteAppTheme()],
    );

    return RepositoryProvider.value(
      value: _themeController,
      child: BlocProvider<DashboardBloc>(
        create: (context) => sl<DashboardBloc>()..add(const GetProjectList()),
        child: ValueListenableBuilder<bool>(
          valueListenable: _themeController.whiteTheme,
          builder: (context, whiteEnabled, _) => MaterialApp.router(
            title: 'Dropline',
            theme: whiteEnabled ? whiteTheme : currentTheme,
            themeAnimationDuration: Duration.zero,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}
