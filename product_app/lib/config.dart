import 'package:flutter/foundation.dart';

/// API URL — chosen automatically:
///  - Web (Chrome on laptop, Safari on iPhone): same computer that serves the
///    web page, port 8000. e.g. page http://192.168.1.10:8090 → API http://192.168.1.10:8000/api
///  - Android Emulator : http://10.0.2.2:8000/api
///  - iOS Simulator    : http://127.0.0.1:8000/api
///  - ទូរស័ព្ទពិត (native app): ប្ដូរ [_deviceHost] ទៅ IP កុំព្យូទ័រ (ឧ. 192.168.1.10)
/// Laravel ត្រូវ run ដោយ: php artisan serve --host=0.0.0.0 --port=8000
class AppConfig {
  static const _deviceHost = ''; // e.g. '192.168.1.10' for a real phone build

  static String get baseUrl {
    if (kIsWeb) return 'http://${Uri.base.host}:8000/api';
    if (_deviceHost.isNotEmpty) return 'http://$_deviceHost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }
}
