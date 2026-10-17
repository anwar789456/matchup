import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart' as impl;

/// True while `flutter test` runs (debug-only helpers stay out of the widget tests).
bool get isWidgetTest => impl.isWidgetTest;
