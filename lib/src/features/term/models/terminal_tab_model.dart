class TerminalTabModel {
  final String id;
  final String title;
  final List<String> history;
  final bool isExecuting;

  const TerminalTabModel({
    required this.id,
    required this.title,
    this.history = const [],
    this.isExecuting = false,
  });

  TerminalTabModel copyWith({
    String? id,
    String? title,
    List<String>? history,
    bool? isExecuting,
  }) {
    return TerminalTabModel(
      id: id ?? this.id,
      title: title ?? this.title,
      history: history ?? this.history,
      isExecuting: isExecuting ?? this.isExecuting,
    );
  }

  factory TerminalTabModel.create({String? title}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return TerminalTabModel(
      id: 'tab_$timestamp',
      title: title ?? 'Terminal ${timestamp % 1000}',
    );
  }
}
