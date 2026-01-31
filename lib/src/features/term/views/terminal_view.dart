import 'package:f_term/src/features/settings/routes/setting_routes.dart';
import 'package:f_term/src/features/settings/view_models/setting_view_model.dart';
import 'package:f_term/src/features/term/models/terminal_tab_model.dart';
import 'package:f_term/src/features/term/view_models/terminal_view_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TerminalView extends StatefulWidget {
  final TerminalViewModel terminalViewModel;
  final SettingViewModel settingViewModel;

  const TerminalView({
    super.key,
    required this.terminalViewModel,
    required this.settingViewModel,
  });

  @override
  State<TerminalView> createState() => _TerminalViewState();
}

class _TerminalViewState extends State<TerminalView>
    with TickerProviderStateMixin {
  late final TextEditingController inputController;
  late final ScrollController scrollController;
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    inputController = TextEditingController();
    scrollController = ScrollController();
    _initializeTabController();
    widget.terminalViewModel.addListener(_onViewModelChanged);
    tabController.addListener(_onTabControllerChanged);
  }

  void _initializeTabController() {
    tabController = TabController(
      length: widget.terminalViewModel.tabs.length,
      vsync: this,
      initialIndex: widget.terminalViewModel.currentTabIndex,
    );
  }

  void _onTabControllerChanged() {
    if (!tabController.indexIsChanging &&
        tabController.index != widget.terminalViewModel.currentTabIndex) {
      widget.terminalViewModel.switchTab(tabController.index);
    }
  }

  void _onViewModelChanged() {
    _scrollToBottom();
    if (tabController.length != widget.terminalViewModel.tabs.length) {
      tabController.removeListener(_onTabControllerChanged);
      final currentIndex = widget.terminalViewModel.currentTabIndex;
      tabController.dispose();
      tabController = TabController(
        length: widget.terminalViewModel.tabs.length,
        vsync: this,
        initialIndex: currentIndex.clamp(
          0,
          widget.terminalViewModel.tabs.length - 1,
        ),
      );
      tabController.addListener(_onTabControllerChanged);
      if (mounted) {
        setState(() {});
      }
    } else if (tabController.index !=
        widget.terminalViewModel.currentTabIndex) {
      tabController.animateTo(widget.terminalViewModel.currentTabIndex);
    }
  }

  @override
  void dispose() {
    // widget.terminalViewModel.removeListener(_onViewModelChanged);
    tabController.removeListener(_onTabControllerChanged);
    inputController.dispose();
    scrollController.dispose();
    tabController.dispose();
    // widget.terminalViewModel.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmit(String command) {
    if (command.trim().isNotEmpty) {
      widget.terminalViewModel.executeCommand(command);
      inputController.clear();
    }
  }

  void _showRenameDialog(int index) {
    final tab = widget.terminalViewModel.tabs[index];
    final controller = TextEditingController(text: tab.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renomear Aba'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da aba',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.terminalViewModel.renameTab(index, value);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                context.pop();
                // Navigator.pop(context);
              },
            ),
            FilledButton(
              child: const Text('Renomear'),
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  widget.terminalViewModel.renameTab(index, newTitle);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(TerminalTabModel tab, int index) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tab.isExecuting)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          GestureDetector(
            child: Text(
              tab.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onDoubleTap: () {
              _showRenameDialog(index);
            },
          ),
          if (widget.terminalViewModel.tabs.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                child: const Icon(Icons.close, size: 16),
                onTap: () {
                  widget.terminalViewModel.removeTab(index);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.terminalViewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Terminal Emulator'),
            actions: [
              IconButton(
                tooltip: 'Nova aba',
                icon: const Icon(Icons.add),
                onPressed: () {
                  widget.terminalViewModel.addTab();
                },
              ),
              IconButton(
                tooltip: 'Limpar terminal',
                icon: const Icon(Icons.cleaning_services_outlined),
                onPressed: () {
                  widget.terminalViewModel.clearCurrentTerminal();
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  context.push(SettingRoutes.setting);
                },
              ),
            ],
            bottom: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: widget.terminalViewModel.tabs
                  .asMap()
                  .entries
                  .map((entry) => _buildTab(entry.value, entry.key))
                  .toList(),
            ),
          ),
          body: TabBarView(
            controller: tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: widget.terminalViewModel.tabs.map((tab) {
              return _buildTerminalContent(tab);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTerminalContent(TerminalTabModel tab) {
    final isDarkTheme = widget.settingViewModel.settingModel.isDarkTheme;
    return Column(
      children: [
        Expanded(
          child: tab.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 64,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Digite um comando para começar',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: tab.history.length,
                  itemBuilder: (context, index) {
                    final line = tab.history[index];
                    final isCommand = line.startsWith('\$');
                    final isError = line.startsWith('Erro:');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: isCommand
                              ? Colors.green
                              : isError
                              ? Colors.red
                              : isDarkTheme
                              ? Colors.white
                              : Colors.black,
                          fontWeight: isCommand
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: inputController,
            onSubmitted: _handleSubmit,
            enabled: !tab.isExecuting,
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.chevron_right),
              suffixIcon: tab.isExecuting
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.send),
              hintText: tab.isExecuting
                  ? 'Executando comando...'
                  : 'Digite um comando...',
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
