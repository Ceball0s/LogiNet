import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class Constants {
  static String get apiUrl => kIsWeb
      ? 'http://localhost:5207'
      : (Platform.isAndroid
          ? 'http://10.0.2.2:5207'
          : 'http://localhost:5207');
}
