// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/foundation.dart';

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

enum BuildMode { release, profile, debug }

enum LevelMessages { debug, info, warning, error }

typedef EasyLogPrinter = Function(Object object, {String? name, LevelMessages? level, StackTrace? stackTrace});

EasyLogPrinter easyLogDefaultPrinter = (Object object, {String? name, StackTrace? stackTrace, LevelMessages? level}) {
  String _coloredString(String string) {
    switch (level) {
      case LevelMessages.debug:
        return '';
      case LevelMessages.info:
        return '';
      case LevelMessages.warning:
        return '';
      case LevelMessages.error:
        return '';
      default:
        return '';
    }
  }

  String _prepareObject() {
    switch (level) {
      case LevelMessages.debug:
        return _coloredString('[$name] [DEBUG] ${object.toString()}');
      case LevelMessages.info:
        return _coloredString('[$name] [INFO] ${object.toString()}');
      case LevelMessages.warning:
        return _coloredString('[$name] [WARNING] ${object.toString()}');
      case LevelMessages.error:
        return _coloredString('[$name] [ERROR] ${object.toString()}');
      default:
        return _coloredString('[$name] ${object.toString()}');
    }
  }

  // print(_prepareObject());

  if (stackTrace != null) {
    // print(_coloredString('__________________________________'));
    // print(_coloredString('${stackTrace.toString()}'));
  }
};
