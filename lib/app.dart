import 'package:dropline/core/router/app_router.dart';

import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dropline',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
