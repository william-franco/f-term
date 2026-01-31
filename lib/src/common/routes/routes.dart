import 'package:f_term/src/features/settings/routes/setting_routes.dart';
import 'package:f_term/src/features/term/routes/terminal_routes.dart';
import 'package:go_router/go_router.dart';

class Routes {
  static String get home => TerminalRoutes.terminal;

  GoRouter get routes => _routes;

  final GoRouter _routes = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: home,
    routes: [...TerminalRoutes().routes, ...SettingRoutes().routes],
  );
}
