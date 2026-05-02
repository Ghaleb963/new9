import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/id_generator.dart';
import './device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  static const String _storageKey = 'dynamic_device_unique_id';

  @override
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  @override
  Future<String> rotateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = IdGenerator.generateDynamicDeviceId();
    await prefs.setString(_storageKey, newId);
    return newId;
  }
}
