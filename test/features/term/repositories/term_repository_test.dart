import 'package:f_term/src/features/term/models/terminal_command_result_model.dart';
import 'package:f_term/src/features/term/repositories/terminal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../term_mocks.mocks.dart';

void main() {
  group('TerminalRepository Test', () {
    late MockTerminalService mockTerminalService;
    late TerminalRepository repository;

    setUp(() {
      mockTerminalService = MockTerminalService();
      repository = TerminalRepositoryImpl(terminalService: mockTerminalService);
    });

    // ---------------------------------------------------------------------------
    // executeCommand
    // ---------------------------------------------------------------------------

    group('executeCommand', () {
      test('should return error result when command is empty', () async {
        // act
        final result = await repository.executeCommand('');

        // assert
        expect(result.isSuccess, isFalse);
        expect(result.exitCode, equals(-1));
        expect(result.errorMessage, equals('Comando vazio não é permitido'));
        verifyNever(mockTerminalService.executeCommand(any));
      });

      test(
        'should return error result when command is only whitespace',
        () async {
          // act
          final result = await repository.executeCommand('   ');

          // assert
          expect(result.isSuccess, isFalse);
          expect(result.exitCode, equals(-1));
          verifyNever(mockTerminalService.executeCommand(any));
        },
      );

      test(
        'should return success result when service returns valid output',
        () async {
          // arrange
          when(
            mockTerminalService.executeCommand(any),
          ).thenAnswer((_) async => 'hello world');

          // act
          final result = await repository.executeCommand('echo hello world');

          // assert
          expect(result.isSuccess, isTrue);
          expect(result.exitCode, equals(0));
          expect(result.output, equals('hello world'));
          expect(result.errorMessage, isNull);
          verify(
            mockTerminalService.executeCommand('echo hello world'),
          ).called(1);
        },
      );

      test('should return error result with exitCode 1 '
          'when service output starts with "Erro:"', () async {
        // arrange
        when(
          mockTerminalService.executeCommand(any),
        ).thenAnswer((_) async => 'Erro: command not found');

        // act
        final result = await repository.executeCommand('invalid_cmd');

        // assert
        expect(result.isSuccess, isFalse);
        expect(result.exitCode, equals(1));
        expect(result.errorMessage, equals('command not found'));
        expect(result.output, equals(''));
      });

      test(
        'should trim the error message when output starts with "Erro:"',
        () async {
          // arrange
          when(
            mockTerminalService.executeCommand(any),
          ).thenAnswer((_) async => 'Erro:   spaced error   ');

          // act
          final result = await repository.executeCommand('cmd');

          // assert
          expect(result.errorMessage, equals('spaced error'));
        },
      );

      test('should return error result with exitCode -1 '
          'when service throws an Exception', () async {
        // arrange
        when(
          mockTerminalService.executeCommand(any),
        ).thenThrow(Exception('permission denied'));

        // act
        final result = await repository.executeCommand('sudo rm -rf /');

        // assert
        expect(result.isSuccess, isFalse);
        expect(result.exitCode, equals(-1));
        expect(result.errorMessage, equals('permission denied'));
      });

      test(
        'should strip "Exception: " prefix from the error message',
        () async {
          // arrange
          when(
            mockTerminalService.executeCommand(any),
          ).thenThrow(Exception('raw error'));

          // act
          final result = await repository.executeCommand('cmd');

          // assert — replaceFirst('Exception: ', '') is applied
          expect(result.errorMessage, equals('raw error'));
        },
      );

      test('should return error result with "Erro inesperado:" prefix '
          'when a non-Exception is thrown', () async {
        // arrange
        when(
          mockTerminalService.executeCommand(any),
        ).thenThrow(StateError('unexpected state'));

        // act
        final result = await repository.executeCommand('cmd');

        // assert
        expect(result.isSuccess, isFalse);
        expect(result.exitCode, equals(-1));
        expect(result.errorMessage, contains('Erro inesperado:'));
      });

      test('should set executedAt to a recent DateTime on success', () async {
        // arrange
        final before = DateTime.now();
        when(
          mockTerminalService.executeCommand(any),
        ).thenAnswer((_) async => 'ok');

        // act
        final result = await repository.executeCommand('ls');
        final after = DateTime.now();

        // assert
        expect(
          result.executedAt.isAfter(before) ||
              result.executedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(result.executedAt.isBefore(after), isTrue);
      });
    });

    // ---------------------------------------------------------------------------
    // executeCommandStream
    // ---------------------------------------------------------------------------

    group('executeCommandStream', () {
      test('should emit a single SuccessResult for a valid command', () async {
        // arrange
        when(
          mockTerminalService.executeCommand(any),
        ).thenAnswer((_) async => 'stream output');

        // act
        final stream = repository.executeCommandStream('ls');

        // assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<TerminalCommandResultModel>(
              (r) => r.isSuccess && r.output == 'stream output',
            ),
            emitsDone,
          ]),
        );
      });

      test('should emit a single ErrorResult for an empty command', () async {
        // act
        final stream = repository.executeCommandStream('');

        // assert
        await expectLater(
          stream,
          emitsInOrder([
            predicate<TerminalCommandResultModel>(
              (r) => !r.isSuccess && r.exitCode == -1,
            ),
            emitsDone,
          ]),
        );
      });

      test('should emit exactly one event and then close the stream', () async {
        // arrange
        when(
          mockTerminalService.executeCommand(any),
        ).thenAnswer((_) async => 'output');

        // act
        final events = await repository.executeCommandStream('pwd').toList();

        // assert
        expect(events.length, equals(1));
      });
    });

    // ---------------------------------------------------------------------------
    // TerminalCommandResultModel — displayText
    // ---------------------------------------------------------------------------

    group('TerminalCommandResultModel displayText', () {
      test('should return output when isSuccess is true', () {
        final model = TerminalCommandResultModel.success('ls output');
        expect(model.displayText, equals('ls output'));
      });

      test('should return errorMessage when isSuccess is false', () {
        final model = TerminalCommandResultModel.error('permission denied');
        expect(model.displayText, equals('permission denied'));
      });

      test('should return "Erro desconhecido" when isSuccess is false '
          'and errorMessage is null', () {
        final model = TerminalCommandResultModel(
          output: '',
          exitCode: 1,
          isSuccess: false,
          executedAt: null,
        );
        expect(model.displayText, equals('Erro desconhecido'));
      });
    });
  });
}
