import 'dart:math';

class IdGenerator {
  /// توليد معرف فريد يدمج بين الوقت الحالي ورقم عشوائي ضخم
  static String generateDynamicDeviceId() {
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final int randomPart = Random().nextInt(999999999) + 100000000; // رقم من 9 خانات
    return 'DEVICE_${timestamp}_$randomPart';
  }
}
