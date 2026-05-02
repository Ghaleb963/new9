import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

// [إصلاح #2] تم حذف الدالة getDeviceId() الثابتة (Dead Code).
// هذه الدالة كانت موجودة لكن لم تُستدعى من أي مكان في التطبيق،
// لأن منطق الجهاز تحوّل إلى DeviceRepositoryImpl + IdGenerator.
// إبقاء الكود الميت يُربك القارئ ويخالف مبدأ Clean Code (YAGNI).
//
// [إصلاح #5] تم نقل ثوابت التشفير (salt, secret key, logout salt)
// من Hardcoded strings داخل الدوال إلى AppConstants.
// السبب: مبدأ DRY (Don't Repeat Yourself) — أي قيمة تُستخدم في أكثر
// من مكان يجب أن تُعرَّف في مكان واحد. هذا يُسهّل التعديل المستقبلي
// دون الحاجة للبحث داخل منطق التشفير.

class EncryptionHelper {
  /// توليد كود المستخدم من معرف الجهاز باستخدام SHA-256
  static String encryptDeviceIdForUser(String deviceId) {
    final bytes = utf8.encode('$deviceId${AppConstants.encryptionSalt}');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// توليد كود التفعيل من كود المستخدم باستخدام SHA-1
  static String generateActivationCode(String userCode) {
    final bytes =
        utf8.encode('$userCode${AppConstants.activationSecretKey}');
    final digest = sha1.convert(bytes);
    return digest.toString().substring(0, 12).toUpperCase();
  }

  /// التحقق من صحة كود التفعيل المُدخل
  static bool verifyActivation(String deviceId, String inputCode) {
    final userCode = encryptDeviceIdForUser(deviceId);
    final expectedCode = generateActivationCode(userCode);
    return inputCode == expectedCode;
  }

  /// توليد كود تسجيل الخروج باستخدام MD5
  static String generateLogoutCode(String deviceId) {
    final bytes = utf8.encode('$deviceId${AppConstants.logoutSalt}');
    final digest = md5.convert(bytes);
    return digest.toString().substring(0, 10).toUpperCase();
  }
}
