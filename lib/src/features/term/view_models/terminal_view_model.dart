import 'package:f_term/src/features/term/models/terminal_tab_model.dart';
import 'package:f_term/src/features/term/repositories/terminal_repository.dart';
import 'package:flutter/foundation.dart';

typedef _ViewModel = ChangeNotifier;

abstract interface class TerminalViewModel extends _ViewModel {
  List<TerminalTabModel> get tabs;
  int get currentTabIndex;
  TerminalTabModel get currentTab;
  bool get isExecuting;
  List<String> get currentHistory;

  void addTab({String? title});
  void removeTab(int index);
  void switchTab(int index);
  void renameTab(int index, String newTitle);
  Future<void> executeCommand(String command);
  void clearCurrentTerminal();
}

class TerminalViewModelImpl extends _ViewModel implements TerminalViewModel {
  final TerminalRepository terminalRepository;

  TerminalViewModelImpl({required this.terminalRepository}) {
    _tabs.add(TerminalTabModel.create(title: 'Terminal 1'));
  }

  final List<TerminalTabModel> _tabs = [];

  @override
  List<TerminalTabModel> get tabs => List.unmodifiable(_tabs);

  int _currentTabIndex = 0;

  @override
  int get currentTabIndex => _currentTabIndex;

  @override
  TerminalTabModel get currentTab => _tabs[_currentTabIndex];

  @override
  bool get isExecuting => currentTab.isExecuting;

  @override
  List<String> get currentHistory => currentTab.history;

  @override
  void addTab({String? title}) {
    final newTab = TerminalTabModel.create(
      title: title ?? 'Terminal ${_tabs.length + 1}',
    );
    _tabs.add(newTab);
    _currentTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  @override
  void removeTab(int index) {
    if (_tabs.length <= 1) {
      return;
    }

    _tabs.removeAt(index);

    if (_currentTabIndex >= _tabs.length) {
      _currentTabIndex = _tabs.length - 1;
    } else if (index < _currentTabIndex) {
      _currentTabIndex--;
    }

    notifyListeners();
  }

  @override
  void switchTab(int index) {
    if (index >= 0 && index < _tabs.length && index != _currentTabIndex) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  @override
  void renameTab(int index, String newTitle) {
    if (index >= 0 && index < _tabs.length && newTitle.trim().isNotEmpty) {
      _tabs[index] = _tabs[index].copyWith(title: newTitle.trim());
      notifyListeners();
    }
  }

  @override
  Future<void> executeCommand(String command) async {
    if (command.trim().isEmpty || currentTab.isExecuting) return;

    _tabs[_currentTabIndex] = currentTab.copyWith(
      isExecuting: true,
      history: [...currentTab.history, '\$ $command'],
    );
    notifyListeners();

    try {
      final result = await terminalRepository.executeCommand(command);

      _tabs[_currentTabIndex] = currentTab.copyWith(
        history: [...currentTab.history, result.displayText],
        isExecuting: false,
      );
    } catch (error) {
      _tabs[_currentTabIndex] = currentTab.copyWith(
        history: [...currentTab.history, 'Erro inesperado: $error'],
        isExecuting: false,
      );
    }

    notifyListeners();
  }

  @override
  void clearCurrentTerminal() {
    _tabs[_currentTabIndex] = currentTab.copyWith(history: []);
    notifyListeners();
  }

  @override
  void dispose() {
    _tabs.clear();
    super.dispose();
  }
}
