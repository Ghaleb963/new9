abstract class DeviceRepository {
  /// جلب المعرف الحالي من التخزين المحلي
  Future<String?> getDeviceId();
  
  /// توليد وحفظ معرف جديد (يُستدعى عند تسجيل الخروج)
  Future<String> rotateDeviceId();
}
