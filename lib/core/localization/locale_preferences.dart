import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/gen/translations.g.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_preferences.g.dart';

@Riverpod(keepAlive: true)
class LocalePreferences extends _$LocalePreferences with AppLogger {
  @override
  AppLocale build() {
    final persisted = ref
        .watch(sharedPreferencesProvider)
        .requireValue
        .getString("locale");
    if (persisted == null) return _deviceLocale();
    // keep backward compatibility with chinese after changing zh to zh_CN
    if (persisted == "zh") {
      return AppLocale.zhCn;
    }
    try {
      return _supportedLocale(AppLocale.values.byName(persisted));
    } catch (e) {
      loggy.error("error setting locale: [$persisted]", e);
      return AppLocale.en;
    }
  }

  Future<void> changeLocale(AppLocale value) async {
    final locale = _supportedLocale(value);
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .requireValue
        .setString("locale", locale.name);
  }

  AppLocale _deviceLocale() {
    final locale = AppLocaleUtils.findDeviceLocale();
    return _supportedLocale(locale);
  }

  AppLocale _supportedLocale(AppLocale locale) => switch (locale) {
    AppLocale.zhCn => AppLocale.zhCn,
    _ => AppLocale.en,
  };
}
