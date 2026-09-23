import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/user_controller.dart';
import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';

/// Root widget for the WORKBRIDGE application.
///
/// Configures theme, routes, and provides [UserController] to the widget tree.
/// In development mode ([kDebugMode]), Flutter hot reload triggers [reassemble]
/// which resets navigation flow back to [SplashView] so condition-based routing
/// and whole-app verification execute on reload rather than staying on a sub-screen.
class WorkBridgeApp extends StatefulWidget {
  const WorkBridgeApp({super.key});

  /// Global navigator key allowing programmatic navigation without BuildContext,
  /// including routing to [SplashView] on hot reload during development.
  static GlobalKey<NavigatorState> get navigatorKey => AppRoutes.navigatorKey;

  @override
  State<WorkBridgeApp> createState() => _WorkBridgeAppState();
}

class _WorkBridgeAppState extends State<WorkBridgeApp> {
  @override
  void reassemble() {
    super.reassemble();
    // In Flutter development, hot reload calls reassemble() across mounted State objects.
    // When hot reload is executed during development (kDebugMode), restart from SplashView
    // so the app restarts the route from splash screen and validates role conditions.
    if (kDebugMode) {
      AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.splash,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserController()),
      ],
      child: MaterialApp(
        navigatorKey: AppRoutes.navigatorKey,
        title: 'WorkBridge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
