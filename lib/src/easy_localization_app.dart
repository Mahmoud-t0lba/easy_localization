// ignore_for_file: unnecessary_getters_setters

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/easy_localization_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'asset_loader.dart';
import 'localization.dart';
import 'logger.dart';

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
