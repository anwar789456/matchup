import 'dart:io';

bool get isWidgetTest => Platform.environment.containsKey('FLUTTER_TEST');
