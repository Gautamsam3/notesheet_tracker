// lib/utils/locator.dart
import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/event_service.dart';
import '../services/notesheet_service.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../services/user_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Register services as singletons
  locator.registerLazySingleton<AuthService>(() => AuthService());
  locator.registerLazySingleton<AdminService>(() => AdminService());
  locator.registerLazySingleton<EventService>(() => EventService());
  locator.registerLazySingleton<NotesheetService>(() => NotesheetService());
  locator.registerLazySingleton<ReviewService>(() => ReviewService());
  locator.registerLazySingleton<SettingsService>(() => SettingsService());
  locator.registerLazySingleton(() => UserService());

  // If a service depends on another, you can pass it in:
  // locator.registerLazySingleton<SomeService>(() => SomeService(locator<AnotherService>()));
  // For now, our services are independent at their constructor level.
}
