import 'package:f_term/src/features/term/models/terminal_tab_model.dart';

class TerminalState {
  final List<TerminalTabModel> tabs;
  final int currentTabIndex;

  TerminalTabModel get currentTab => tabs[currentTabIndex];
  bool get isExecuting => currentTab.isExecuting;
  List<String> get currentHistory => currentTab.history;

  const TerminalState({
    required this.tabs,
    required this.currentTabIndex,
  });

  TerminalState copyWith({
    List<TerminalTabModel>? tabs,
    int? currentTabIndex,
  }) => TerminalState(
    tabs: tabs ?? this.tabs,
    currentTabIndex: currentTabIndex ?? this.currentTabIndex,
  );
}
