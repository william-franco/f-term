import 'package:f_term/src/common/dependency_injectors/dependency_injector.dart';
import 'package:f_term/src/features/settings/view_models/setting_view_model.dart';
import 'package:f_term/src/features/term/view_models/terminal_view_model.dart';
import 'package:f_term/src/features/term/views/terminal_view.dart';
import 'package:go_router/go_router.dart';

class TerminalRoutes {
  static String get terminal => '/terminal';

  List<GoRoute> get routes => _routes;

  final List<GoRoute> _routes = [
    GoRoute(
      path: terminal,
      builder: (context, state) {
        return TerminalView(
          terminalViewModel: locator<TerminalViewModel>(),
          settingViewModel: locator<SettingViewModel>(),
        );
      },
    ),
  ];
}
