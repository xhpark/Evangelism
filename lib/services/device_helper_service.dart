import 'package:wakelock_plus/wakelock_plus.dart';

class DeviceHelperService {
  static Future<void> enableKeepScreenOn() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  static Future<void> disableKeepScreenOn() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }
}
