import 'package:f_term/src/features/term/models/terminal_command_result_model.dart';
import 'package:f_term/src/features/term/models/terminal_state_model.dart';
import 'package:f_term/src/features/term/view_models/terminal_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../term_mocks.mocks.dart';

void main() {
  group('TerminalViewModel Test', () {
    late MockTerminalRepository mockTerminalRepository;
    late TerminalViewModel viewModel;

    setUpAll(() {
      provideDummy<TerminalCommandResultModel>(
        TerminalCommandResultModel.success(''),
      );
    });

    setUp(() {
      mockTerminalRepository = MockTerminalRepository();
      viewModel = TerminalViewModelImpl(
        terminalRepository: mockTerminalRepository,
      );
    });

    tearDown(() {
      viewModel.dispose();
    });

    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------

    group('initial state', () {
      test('should start with one tab', () {
        expect(viewModel.state.tabs.length, equals(1));
      });

      test('should start with currentTabIndex 0', () {
        expect(viewModel.state.currentTabIndex, equals(0));
      });

      test('should start with isExecuting false', () {
        expect(viewModel.state.isExecuting, isFalse);
      });

      test('should start with an empty history on the first tab', () {
        expect(viewModel.state.currentHistory, isEmpty);
      });
    });

    // ---------------------------------------------------------------------------
    // addTab
    // ---------------------------------------------------------------------------

    group('addTab', () {
      test('should add a new tab and switch to it', () {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        viewModel.addTab();

        // assert
        expect(viewModel.state.tabs.length, equals(2));
        expect(viewModel.state.currentTabIndex, equals(1));
        expect(notifyCount, equals(1));
      });

      test('should use the provided title when adding a tab', () {
        // act
        viewModel.addTab(title: 'My Tab');

        // assert
        expect(viewModel.state.tabs.last.title, equals('My Tab'));
      });

      test('should generate a default title when no title is provided', () {
        // act
        viewModel.addTab();

        // assert — default title contains "Terminal"
        expect(viewModel.state.tabs.last.title, contains('Terminal'));
      });

      test('should keep previous tabs intact when a new tab is added', () {
        // arrange
        final firstTabId = viewModel.state.tabs.first.id;

        // act
        viewModel.addTab();

        // assert
        expect(viewModel.state.tabs.first.id, equals(firstTabId));
      });
    });

    // ---------------------------------------------------------------------------
    // removeTab
    // ---------------------------------------------------------------------------

    group('removeTab', () {
      test('should not remove the last remaining tab', () {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        viewModel.removeTab(0);

        // assert
        expect(viewModel.state.tabs.length, equals(1));
        expect(notifyCount, equals(0));
      });

      test('should remove a tab by index when more than one tab exists', () {
        // arrange
        viewModel.addTab();
        viewModel.addTab();
        expect(viewModel.state.tabs.length, equals(3));

        // act
        viewModel.removeTab(1);

        // assert
        expect(viewModel.state.tabs.length, equals(2));
      });

      test('should adjust currentTabIndex when the active tab is removed', () {
        // arrange — add a second tab and switch to it
        viewModel.addTab();
        viewModel.switchTab(1);
        expect(viewModel.state.currentTabIndex, equals(1));

        // act — remove the active tab (index 1)
        viewModel.removeTab(1);

        // assert — index clamped to last available
        expect(viewModel.state.currentTabIndex, equals(0));
      });

      test(
        'should decrement currentTabIndex when a tab before it is removed',
        () {
          // arrange — three tabs, active on index 2
          viewModel.addTab();
          viewModel.addTab();
          viewModel.switchTab(2);

          // act — remove tab at index 0 (before active)
          viewModel.removeTab(0);

          // assert — active index decrements by 1
          expect(viewModel.state.currentTabIndex, equals(1));
        },
      );

      test(
        'should not change currentTabIndex when a tab after it is removed',
        () {
          // arrange — two tabs, stay on index 0
          viewModel.addTab();
          expect(viewModel.state.currentTabIndex, equals(1));
          viewModel.switchTab(0);

          // act — remove tab at index 1 (after active)
          viewModel.removeTab(1);

          // assert
          expect(viewModel.state.currentTabIndex, equals(0));
        },
      );
    });

    // ---------------------------------------------------------------------------
    // switchTab
    // ---------------------------------------------------------------------------

    group('switchTab', () {
      test('should switch to the given index', () {
        // arrange
        viewModel.addTab();

        // act
        viewModel.switchTab(0);

        // assert
        expect(viewModel.state.currentTabIndex, equals(0));
      });

      test('should not emit when switching to the already active tab', () {
        // arrange
        viewModel.addTab();
        viewModel.switchTab(1);
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act — already on index 1
        viewModel.switchTab(1);

        // assert
        expect(notifyCount, equals(0));
      });

      test('should not emit when index is out of bounds', () {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        viewModel.switchTab(-1);
        viewModel.switchTab(99);

        // assert
        expect(notifyCount, equals(0));
      });
    });

    // ---------------------------------------------------------------------------
    // renameTab
    // ---------------------------------------------------------------------------

    group('renameTab', () {
      test('should rename the tab at the given index', () {
        // act
        viewModel.renameTab(0, 'Renamed');

        // assert
        expect(viewModel.state.tabs.first.title, equals('Renamed'));
      });

      test('should trim whitespace from the new title', () {
        // act
        viewModel.renameTab(0, '  Trimmed  ');

        // assert
        expect(viewModel.state.tabs.first.title, equals('Trimmed'));
      });

      test('should not emit when new title is empty or only whitespace', () {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        viewModel.renameTab(0, '');
        viewModel.renameTab(0, '   ');

        // assert
        expect(notifyCount, equals(0));
      });

      test('should not emit when index is out of bounds', () {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        viewModel.renameTab(-1, 'Bad');
        viewModel.renameTab(99, 'Bad');

        // assert
        expect(notifyCount, equals(0));
      });

      test(
        'should only rename the targeted tab and leave others unchanged',
        () {
          // arrange
          viewModel.addTab(title: 'Second');
          final secondId = viewModel.state.tabs[1].id;

          // act
          viewModel.renameTab(0, 'First Renamed');

          // assert
          expect(viewModel.state.tabs[0].title, equals('First Renamed'));
          expect(viewModel.state.tabs[1].id, equals(secondId));
        },
      );
    });

    // ---------------------------------------------------------------------------
    // executeCommand
    // ---------------------------------------------------------------------------

    group('executeCommand', () {
      test('should emit [isExecuting=true, isExecuting=false] '
          'and append command + result to history', () async {
        // arrange
        when(
          mockTerminalRepository.executeCommand(any),
        ).thenAnswer((_) async => TerminalCommandResultModel.success('hello'));

        final states = <TerminalStateModel>[];
        viewModel.addListener(() => states.add(viewModel.state));

        // act
        await viewModel.executeCommand('echo hello');

        // assert
        expect(states.length, equals(2));
        expect(states[0].isExecuting, isTrue);
        expect(states[0].currentHistory, contains('\$ echo hello'));
        expect(states[1].isExecuting, isFalse);
        expect(states[1].currentHistory, contains('hello'));
      });

      test('should not execute when command is empty', () async {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        await viewModel.executeCommand('');
        await viewModel.executeCommand('   ');

        // assert
        expect(notifyCount, equals(0));
        verifyNever(mockTerminalRepository.executeCommand(any));
      });

      test('should not execute when isExecuting is already true', () async {
        // arrange — put the tab in executing state manually
        when(mockTerminalRepository.executeCommand(any)).thenAnswer((_) async {
          // trigger a second call while the first is running
          await viewModel.executeCommand('second');
          return TerminalCommandResultModel.success('first result');
        });

        // act
        await viewModel.executeCommand('first');

        // assert — repository called only once (second call was blocked)
        verify(mockTerminalRepository.executeCommand(any)).called(1);
      });

      test(
        'should append error message to history when repository throws',
        () async {
          // arrange
          when(
            mockTerminalRepository.executeCommand(any),
          ).thenThrow(Exception('crash'));

          final states = <TerminalStateModel>[];
          viewModel.addListener(() => states.add(viewModel.state));

          // act
          await viewModel.executeCommand('bad-cmd');

          // assert
          expect(states.last.isExecuting, isFalse);
          expect(states.last.currentHistory.last, contains('Erro inesperado:'));
        },
      );

      test(
        'should display the errorMessage from an error result in history',
        () async {
          // arrange
          when(mockTerminalRepository.executeCommand(any)).thenAnswer(
            (_) async => TerminalCommandResultModel.error('command not found'),
          );

          final states = <TerminalStateModel>[];
          viewModel.addListener(() => states.add(viewModel.state));

          // act
          await viewModel.executeCommand('invalid');

          // assert — displayText of error model is the errorMessage
          expect(states.last.currentHistory.last, equals('command not found'));
        },
      );

      test(
        'should execute on the correct tab when not on the first tab',
        () async {
          // arrange
          viewModel.addTab();
          viewModel.switchTab(1);

          when(mockTerminalRepository.executeCommand(any)).thenAnswer(
            (_) async => TerminalCommandResultModel.success('tab2 output'),
          );

          // act
          await viewModel.executeCommand('ls');

          // assert — only tab at index 1 has history
          expect(viewModel.state.tabs[0].history, isEmpty);
          expect(viewModel.state.tabs[1].history, isNotEmpty);
          expect(viewModel.state.tabs[1].history.last, equals('tab2 output'));
        },
      );
    });

    // ---------------------------------------------------------------------------
    // clearCurrentTerminal
    // ---------------------------------------------------------------------------

    group('clearCurrentTerminal', () {
      test('should clear the history of the current tab', () async {
        // arrange — populate history first
        when(
          mockTerminalRepository.executeCommand(any),
        ).thenAnswer((_) async => TerminalCommandResultModel.success('output'));
        await viewModel.executeCommand('ls');
        expect(viewModel.state.currentHistory, isNotEmpty);

        // act
        viewModel.clearCurrentTerminal();

        // assert
        expect(viewModel.state.currentHistory, isEmpty);
      });

      test('should notify listeners once when clearing', () {
        // arrange
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // act
        viewModel.clearCurrentTerminal();

        // assert
        expect(notifyCount, equals(1));
      });

      test(
        'should only clear the active tab and leave others unchanged',
        () async {
          // arrange — populate tab 0, switch to tab 1, clear tab 1
          when(mockTerminalRepository.executeCommand(any)).thenAnswer(
            (_) async => TerminalCommandResultModel.success('output'),
          );
          await viewModel.executeCommand('ls'); // populates tab 0
          viewModel.addTab();
          viewModel.switchTab(1);
          await viewModel.executeCommand('pwd'); // populates tab 1

          expect(viewModel.state.tabs[0].history, isNotEmpty);
          expect(viewModel.state.tabs[1].history, isNotEmpty);

          // act
          viewModel.clearCurrentTerminal();

          // assert
          expect(viewModel.state.tabs[1].history, isEmpty);
          expect(viewModel.state.tabs[0].history, isNotEmpty);
        },
      );
    });
  });
}
