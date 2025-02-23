// ignore_for_file: unnecessary_getters_setters

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:easy_logger/easy_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'asset_loader.dart';
import 'localization.dart';

part 'utils.dart';

class EasyLocalization extends StatefulWidget {
  final Widget child;

  final List<Locale> supportedLocales;

  final Locale? fallbackLocale;

  final Locale? startLocale;

  final bool useOnlyLangCode;

  final bool useFallbackTranslations;

  final bool useFallbackTranslationsForEmptyResources;

  final bool ignorePluralRules;

  final String path;

  // ignore: prefer_typing_uninitialized_variables
  final AssetLoader assetLoader;

  //   runApp(
  //   EasyLocalization(
  //     supportedLocales: const <Locale>[
  //       Locale('en'),
  //     ],
  //     fallbackLocale: const Locale('en'),
  //     assetLoader: const RootBundleAssetLoader(),
  //     extraAssetLoaders: [
  //         TranslationsLoader(packageName: 'package_example_1'),
  //         TranslationsLoader(packageName: 'package_example_2'),
  //     ],
  //     path: 'lib/l10n/translations',
  //     child: const MainApp(),
  //   ),
  // );

  final List<AssetLoader>? extraAssetLoaders;

  final bool saveLocale;

  final Widget Function(FlutterError? message)? errorWidget;

  EasyLocalization({
    Key? key,
    required this.child,
    required this.supportedLocales,
    required this.path,
    this.fallbackLocale,
    this.startLocale,
    this.useOnlyLangCode = false,
    this.useFallbackTranslations = false,
    this.useFallbackTranslationsForEmptyResources = false,
    this.ignorePluralRules = true,
    this.assetLoader = const RootBundleAssetLoader(),
    this.extraAssetLoaders,
    this.saveLocale = true,
    this.errorWidget,
  })  : assert(supportedLocales.isNotEmpty),
        assert(path.isNotEmpty),
        super(key: key) {
    EasyLocalization.logger.debug('Start');
  }

  @override
  // ignore: library_private_types_in_public_api
  _EasyLocalizationState createState() => _EasyLocalizationState();

  // ignore: library_private_types_in_public_api
  static _EasyLocalizationProvider? of(BuildContext context) => _EasyLocalizationProvider.of(context);

  static Future<void> ensureInitialized() async => await EasyLocalizationController.initEasyLocation();

  static EasyLogger logger = EasyLogger(name: '🌎 Easy Localization');
}

class _EasyLocalizationState extends State<EasyLocalization> {
  _EasyLocalizationDelegate? delegate;
  EasyLocalizationController? localizationController;
  FlutterError? translationsLoadError;

  @override
  void initState() {
    EasyLocalization.logger.debug('Init state');
    localizationController = EasyLocalizationController(
      saveLocale: widget.saveLocale,
      fallbackLocale: widget.fallbackLocale,
      supportedLocales: widget.supportedLocales,
      startLocale: widget.startLocale,
      assetLoader: widget.assetLoader,
      extraAssetLoaders: widget.extraAssetLoaders,
      useOnlyLangCode: widget.useOnlyLangCode,
      useFallbackTranslations: widget.useFallbackTranslations,
      path: widget.path,
      onLoadError: (FlutterError e) {
        setState(() {
          translationsLoadError = e;
        });
      },
    );
    // causes localization to rebuild with new language
    localizationController!.addListener(() {
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    localizationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    EasyLocalization.logger.debug('Build');
    if (translationsLoadError != null) {
      return widget.errorWidget != null
          ? widget.errorWidget!(translationsLoadError)
          : ErrorWidget(translationsLoadError!);
    }
    return _EasyLocalizationProvider(
      widget,
      localizationController!,
      delegate: _EasyLocalizationDelegate(
        localizationController: localizationController,
        supportedLocales: widget.supportedLocales,
        useFallbackTranslationsForEmptyResources: widget.useFallbackTranslationsForEmptyResources,
        ignorePluralRules: widget.ignorePluralRules,
      ),
    );
  }
}

class _EasyLocalizationProvider extends InheritedWidget {
  final EasyLocalization parent;
  final EasyLocalizationController _localeState;
  final Locale? currentLocale;
  final _EasyLocalizationDelegate delegate;

  List<LocalizationsDelegate> get delegates => [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  List<Locale> get supportedLocales => parent.supportedLocales;

  // _EasyLocalizationDelegate get delegate => parent.delegate;

  _EasyLocalizationProvider(this.parent, this._localeState, {Key? key, required this.delegate})
      : currentLocale = _localeState.locale,
        super(key: key, child: parent.child) {
    EasyLocalization.logger.debug('Init provider');
  }

  Locale get locale => _localeState.locale;

  Locale? get fallbackLocale => parent.fallbackLocale;

  // Locale get startLocale => parent.startLocale;

  Future<void> setLocale(Locale locale) async {
    // Check old locale
    if (locale != _localeState.locale) {
      assert(parent.supportedLocales.contains(locale));
      await _localeState.setLocale(locale);
    }
  }

  Future<void> deleteSaveLocale() async {
    await _localeState.deleteSaveLocale();
  }

  Locale get deviceLocale => _localeState.deviceLocale;
  Locale? get savedLocale => _localeState.savedLocale;

  Future<void> resetLocale() => _localeState.resetLocale();

  @override
  bool updateShouldNotify(_EasyLocalizationProvider oldWidget) {
    return oldWidget.currentLocale != locale;
  }

  static _EasyLocalizationProvider? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EasyLocalizationProvider>();
}

class _EasyLocalizationDelegate extends LocalizationsDelegate<Localization> {
  final List<Locale>? supportedLocales;
  final EasyLocalizationController? localizationController;
  final bool useFallbackTranslationsForEmptyResources;
  final bool ignorePluralRules;

  // final bool useOnlyLangCode;

  _EasyLocalizationDelegate({
    required this.useFallbackTranslationsForEmptyResources,
    this.ignorePluralRules = true,
    this.localizationController,
    this.supportedLocales,
  }) {
    EasyLocalization.logger.debug('Init Localization Delegate');
  }

  @override
  bool isSupported(Locale locale) => supportedLocales!.contains(locale);

  @override
  Future<Localization> load(Locale value) async {
    EasyLocalization.logger.debug('Load Localization Delegate');
    if (localizationController!.translations == null) {
      await localizationController!.loadTranslations();
    }

    Localization.load(
      value,
      translations: localizationController!.translations,
      fallbackTranslations: localizationController!.fallbackTranslations,
      useFallbackTranslationsForEmptyResources: useFallbackTranslationsForEmptyResources,
      ignorePluralRules: ignorePluralRules,
    );
    return Future.value(Localization.instance);
  }

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => false;
}

class EasyLogger {
  EasyLogger({
    this.name = '',
    this.enableBuildModes = const <BuildMode>[BuildMode.profile, BuildMode.debug],
    this.enableLevels = const <LevelMessages>[
      LevelMessages.debug,
      LevelMessages.info,
      LevelMessages.error,
      LevelMessages.warning,
    ],
    EasyLogPrinter? printer,
    this.defaultLevel = LevelMessages.info,
  }) {
    _printer = printer ?? easyLogDefaultPrinter;
    _currentBuildMode = _getCurrentBuildMode();
  }

  BuildMode? _currentBuildMode;

  String name;

  List<BuildMode> enableBuildModes;

  List<LevelMessages> enableLevels;

  LevelMessages defaultLevel;

  EasyLogPrinter? _printer;

  EasyLogPrinter? get printer => _printer;

  set printer(EasyLogPrinter? newPrinter) => _printer = newPrinter;

  BuildMode _getCurrentBuildMode() {
    if (kReleaseMode) {
      return BuildMode.release;
    } else if (kProfileMode) {
      return BuildMode.profile;
    }
    return BuildMode.debug;
  }

  bool isEnabled(LevelMessages level) {
    if (!enableBuildModes.contains(_currentBuildMode)) {
      return false;
    }
    if (!enableLevels.contains(level)) {
      return false;
    }
    return true;
  }

  void call(Object object, {StackTrace? stackTrace, LevelMessages? level}) {
    level ??= defaultLevel;
    if (isEnabled(level)) {
      _printer!('');
    }
  }

  void debug(Object object, {StackTrace? stackTrace}) =>
      call(object, stackTrace: stackTrace, level: LevelMessages.debug);

  void info(Object object, {StackTrace? stackTrace}) => call(object, stackTrace: stackTrace, level: LevelMessages.info);

  void warning(Object object, {StackTrace? stackTrace}) =>
      call(object, stackTrace: stackTrace, level: LevelMessages.warning);

  void error(Object object, {StackTrace? stackTrace}) =>
      call(object, stackTrace: stackTrace, level: LevelMessages.error);
}
