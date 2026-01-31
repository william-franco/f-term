class TerminalCommandResultModel {
  final String output;
  final int exitCode;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime executedAt;

  const TerminalCommandResultModel({
    required this.output,
    required this.exitCode,
    required this.isSuccess,
    this.errorMessage,
    DateTime? executedAt,
  }) : executedAt = executedAt ?? const Duration(milliseconds: 0) as DateTime;

  factory TerminalCommandResultModel.success(
    String output, {
    int exitCode = 0,
  }) {
    return TerminalCommandResultModel(
      output: output,
      exitCode: exitCode,
      isSuccess: true,
      executedAt: DateTime.now(),
    );
  }

  factory TerminalCommandResultModel.error(String error, {int exitCode = 1}) {
    return TerminalCommandResultModel(
      output: '',
      exitCode: exitCode,
      isSuccess: false,
      errorMessage: error,
      executedAt: DateTime.now(),
    );
  }

  String get displayText {
    if (isSuccess) {
      return output;
    } else {
      return errorMessage ?? 'Erro desconhecido';
    }
  }
}
