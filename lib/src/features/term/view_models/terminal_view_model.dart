import 'package:f_term/src/common/state_management/state_management.dart';
import 'package:f_term/src/features/term/models/terminal_state.dart';
import 'package:f_term/src/features/term/models/terminal_tab_model.dart';
import 'package:f_term/src/features/term/repositories/terminal_repository.dart';

typedef _ViewModel = StateManagement<TerminalState>;

abstract interface class TerminalViewModel extends _ViewModel {
  TerminalViewModel(super.initialState);

  void addTab({String? title});
  void removeTab(int index);
  void switchTab(int index);
  void renameTab(int index, String newTitle);
  Future<void> executeCommand(String command);
  void clearCurrentTerminal();
}

class TerminalViewModelImpl extends _ViewModel implements TerminalViewModel {
  final TerminalRepository terminalRepository;

  TerminalViewModelImpl({required this.terminalRepository})
    : super(
        TerminalState(
          tabs: [TerminalTabModel.create(title: 'Terminal 1')],
          currentTabIndex: 0,
        ),
      );

  @override
  void addTab({String? title}) {
    final newTab = TerminalTabModel.create(
      title: title ?? 'Terminal ${state.tabs.length + 1}',
    );
    emitState(
      state.copyWith(
        tabs: [...state.tabs, newTab],
        currentTabIndex: state.tabs.length,
      ),
    );
  }

  @override
  void removeTab(int index) {
    if (state.tabs.length <= 1) return;

    final updatedTabs = List<TerminalTabModel>.from(state.tabs)
      ..removeAt(index);

    int newIndex = state.currentTabIndex;
    if (newIndex >= updatedTabs.length) {
      newIndex = updatedTabs.length - 1;
    } else if (index < newIndex) {
      newIndex--;
    }

    emitState(state.copyWith(tabs: updatedTabs, currentTabIndex: newIndex));
  }

  @override
  void switchTab(int index) {
    if (index >= 0 &&
        index < state.tabs.length &&
        index != state.currentTabIndex) {
      emitState(state.copyWith(currentTabIndex: index));
    }
  }

  @override
  void renameTab(int index, String newTitle) {
    if (index >= 0 &&
        index < state.tabs.length &&
        newTitle.trim().isNotEmpty) {
      final updatedTabs = List<TerminalTabModel>.from(state.tabs);
      updatedTabs[index] = updatedTabs[index].copyWith(title: newTitle.trim());
      emitState(state.copyWith(tabs: updatedTabs));
    }
  }

  @override
  Future<void> executeCommand(String command) async {
    if (command.trim().isEmpty || state.isExecuting) return;

    final executingTabs = List<TerminalTabModel>.from(state.tabs);
    executingTabs[state.currentTabIndex] = state.currentTab.copyWith(
      isExecuting: true,
      history: [...state.currentTab.history, '\$ $command'],
    );
    emitState(state.copyWith(tabs: executingTabs));

    try {
      final result = await terminalRepository.executeCommand(command);

      final resultTabs = List<TerminalTabModel>.from(state.tabs);
      resultTabs[state.currentTabIndex] = state.currentTab.copyWith(
        history: [...state.currentTab.history, result.displayText],
        isExecuting: false,
      );
      emitState(state.copyWith(tabs: resultTabs));
    } catch (error) {
      final errorTabs = List<TerminalTabModel>.from(state.tabs);
      errorTabs[state.currentTabIndex] = state.currentTab.copyWith(
        history: [...state.currentTab.history, 'Erro inesperado: $error'],
        isExecuting: false,
      );
      emitState(state.copyWith(tabs: errorTabs));
    }
  }

  @override
  void clearCurrentTerminal() {
    final updatedTabs = List<TerminalTabModel>.from(state.tabs);
    updatedTabs[state.currentTabIndex] = state.currentTab.copyWith(
      history: [],
    );
    emitState(state.copyWith(tabs: updatedTabs));
  }
}
