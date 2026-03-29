import 'package:f_term/src/features/term/models/terminal_tab_model.dart';

class TerminalStateModel {
  final List<TerminalTabModel> tabs;
  final int currentTabIndex;

  TerminalTabModel get currentTab => tabs[currentTabIndex];
  bool get isExecuting => currentTab.isExecuting;
  List<String> get currentHistory => currentTab.history;

  TerminalStateModel({required this.tabs, required this.currentTabIndex});

  TerminalStateModel copyWith({
    List<TerminalTabModel>? tabs,
    int? currentTabIndex,
  }) => TerminalStateModel(
    tabs: tabs ?? this.tabs,
    currentTabIndex: currentTabIndex ?? this.currentTabIndex,
  );
}
