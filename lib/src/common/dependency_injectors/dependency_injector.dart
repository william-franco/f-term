import 'package:f_term/src/common/services/storage_service.dart';
import 'package:f_term/src/common/services/terminal_service.dart';
import 'package:f_term/src/features/settings/repositories/setting_repository.dart';
import 'package:f_term/src/features/settings/view_models/setting_view_model.dart';
import 'package:f_term/src/features/term/repositories/terminal_repository.dart';
import 'package:f_term/src/features/term/view_models/terminal_view_model.dart';
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void dependencyInjector() {
  _startTerminalService();
  _startStorageService();
  _startFeatureTerminal();
  _startFeatureSetting();
}

void _startTerminalService() {
  locator.registerLazySingleton<TerminalService>(() => TerminalServiceImpl());
}

void _startStorageService() {
  locator.registerLazySingleton<StorageService>(() => StorageServiceImpl());
}

void _startFeatureTerminal() {
  locator.registerCachedFactory<TerminalRepository>(
    () => TerminalRepositoryImpl(terminalService: locator<TerminalService>()),
  );
  locator.registerLazySingleton<TerminalViewModel>(
    () => TerminalViewModelImpl(
      terminalRepository: locator<TerminalRepository>(),
    ),
  );
}

void _startFeatureSetting() {
  locator.registerCachedFactory<SettingRepository>(
    () => SettingRepositoryImpl(storageService: locator<StorageService>()),
  );
  locator.registerLazySingleton<SettingViewModel>(
    () => SettingViewModelImpl(settingRepository: locator<SettingRepository>()),
  );
}

Future<void> initDependencies() async {
  await locator<StorageService>().initStorage();
  await Future.wait([locator<SettingViewModel>().getTheme()]);
}

void resetDependencies() {
  locator.reset();
}

void resetFeatureSetting() {
  locator.unregister<SettingRepository>();
  locator.unregister<SettingViewModel>();
  _startFeatureSetting();
}
