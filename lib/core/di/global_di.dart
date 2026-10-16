import 'package:dropline/core/di/dashboard_di.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initGlobalDi() async {
  await initDashboardDi();
}
