import 'dart:io';

abstract class TerminalService {
  Future<String> executeCommand(String command);
}

class TerminalServiceImpl implements TerminalService {
  @override
  Future<String> executeCommand(String command) async {
    try {
      final result = await Process.run('bash', ['-c', command]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      } else {
        return 'Erro: ${result.stderr.toString().trim()}';
      }
    } catch (error) {
      throw Exception('Erro ao executar comando: $error');
    }
  }
}
