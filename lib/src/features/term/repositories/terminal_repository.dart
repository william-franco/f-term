import 'package:f_term/src/common/services/terminal_service.dart';
import 'package:f_term/src/features/term/models/terminal_command_result_model.dart';

abstract class TerminalRepository {
  Future<TerminalCommandResultModel> executeCommand(String command);
  Stream<TerminalCommandResultModel> executeCommandStream(String command);
}

class TerminalRepositoryImpl implements TerminalRepository {
  final TerminalService terminalService;

  TerminalRepositoryImpl({required this.terminalService});

  @override
  Future<TerminalCommandResultModel> executeCommand(String command) async {
    try {
      if (command.trim().isEmpty) {
        return TerminalCommandResultModel.error(
          'Comando vazio não é permitido',
          exitCode: -1,
        );
      }

      final output = await terminalService.executeCommand(command);

      if (output.startsWith('Erro:')) {
        return TerminalCommandResultModel.error(
          output.substring(6).trim(),
          exitCode: 1,
        );
      }

      return TerminalCommandResultModel.success(output);
    } on Exception catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      return TerminalCommandResultModel.error(errorMessage, exitCode: -1);
    } catch (e) {
      return TerminalCommandResultModel.error(
        'Erro inesperado: $e',
        exitCode: -1,
      );
    }
  }

  @override
  Stream<TerminalCommandResultModel> executeCommandStream(
    String command,
  ) async* {
    yield await executeCommand(command);
  }
}
