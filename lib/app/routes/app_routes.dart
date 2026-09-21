part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const ONBOARDING = _Paths.ONBOARDING;
  static const CAMERA = _Paths.CAMERA;
  static const TEMPLATES = _Paths.TEMPLATES;
  static const EDITOR = _Paths.EDITOR;
  static const PRINT_SHEET = _Paths.PRINT_SHEET;
  static const EXPORT = _Paths.EXPORT;
  static const HISTORY = _Paths.HISTORY;
  static const SETTINGS = _Paths.SETTINGS;
  static const WIZARD = _Paths.WIZARD;
  static const RESTORATION = _Paths.RESTORATION;
  static const OUTFIT_GALLERY = _Paths.OUTFIT_GALLERY;
  static const OUTFIT_EDITOR = _Paths.OUTFIT_EDITOR;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const ONBOARDING = '/onboarding';
  static const CAMERA = '/camera';
  static const TEMPLATES = '/templates';
  static const EDITOR = '/editor';
  static const PRINT_SHEET = '/print-sheet';
  static const EXPORT = '/export';
  static const HISTORY = '/history';
  static const SETTINGS = '/settings';
  static const WIZARD = '/wizard';
  static const RESTORATION = '/restoration';
  static const OUTFIT_GALLERY = '/outfit-gallery';
  static const OUTFIT_EDITOR = '/outfit-editor';
}
