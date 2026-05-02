import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/core/utils/encryption_helper.dart';

void main() {
  group('EncryptionHelper', () {
    group('encryptDeviceIdForUser', () {
      test('should return 16-character uppercase string', () {
        final result = EncryptionHelper.encryptDeviceIdForUser('test_device_123');
        expect(result.length, 16);
        expect(result, equals(result.toUpperCase()));
      });

      test('should be deterministic (same input = same output)', () {
        final r1 = EncryptionHelper.encryptDeviceIdForUser('my_device');
        final r2 = EncryptionHelper.encryptDeviceIdForUser('my_device');
        expect(r1, equals(r2));
      });

      test('should produce different results for different inputs', () {
        final r1 = EncryptionHelper.encryptDeviceIdForUser('device_a');
        final r2 = EncryptionHelper.encryptDeviceIdForUser('device_b');
        expect(r1, isNot(equals(r2)));
      });
    });

    group('generateActivationCode', () {
      test('should return 12-character uppercase string', () {
        final result = EncryptionHelper.generateActivationCode('ABCDEF1234567890');
        expect(result.length, 12);
        expect(result, equals(result.toUpperCase()));
      });

      test('should be deterministic', () {
        final r1 = EncryptionHelper.generateActivationCode('USER_CODE_1');
        final r2 = EncryptionHelper.generateActivationCode('USER_CODE_1');
        expect(r1, equals(r2));
      });
    });

    group('verifyActivation', () {
      test('should return true for correct activation code', () {
        const deviceId = 'test_device_xyz';
        final userCode = EncryptionHelper.encryptDeviceIdForUser(deviceId);
        final activationCode = EncryptionHelper.generateActivationCode(userCode);

        final isValid = EncryptionHelper.verifyActivation(deviceId, activationCode);
        expect(isValid, isTrue);
      });

      test('should return false for wrong activation code', () {
        const deviceId = 'test_device_xyz';
        final isValid = EncryptionHelper.verifyActivation(deviceId, 'WRONG_CODE_1');
        expect(isValid, isFalse);
      });

      test('should return false for empty code', () {
        const deviceId = 'test_device_xyz';
        final isValid = EncryptionHelper.verifyActivation(deviceId, '');
        expect(isValid, isFalse);
      });

      test('should return false for code from different device', () {
        final userCodeA = EncryptionHelper.encryptDeviceIdForUser('device_a');
        final codeA = EncryptionHelper.generateActivationCode(userCodeA);

        final isValid = EncryptionHelper.verifyActivation('device_b', codeA);
        expect(isValid, isFalse);
      });
    });

    group('generateLogoutCode', () {
      test('should return 10-character uppercase string', () {
        final result = EncryptionHelper.generateLogoutCode('test_device');
        expect(result.length, 10);
        expect(result, equals(result.toUpperCase()));
      });

      test('should be deterministic', () {
        final r1 = EncryptionHelper.generateLogoutCode('device_123');
        final r2 = EncryptionHelper.generateLogoutCode('device_123');
        expect(r1, equals(r2));
      });

      test('should produce different results for different devices', () {
        final r1 = EncryptionHelper.generateLogoutCode('device_a');
        final r2 = EncryptionHelper.generateLogoutCode('device_b');
        expect(r1, isNot(equals(r2)));
      });
    });

    group('Full activation flow', () {
      test('should complete activate → verify → logout cycle', () {
        const deviceId = 'full_flow_device_id_2024';

        // Step 1: Generate user code (shown to user)
        final userCode = EncryptionHelper.encryptDeviceIdForUser(deviceId);
        expect(userCode.length, 16);

        // Step 2: Generate activation code (given by admin)
        final activationCode = EncryptionHelper.generateActivationCode(userCode);
        expect(activationCode.length, 12);

        // Step 3: Verify activation
        final isValid = EncryptionHelper.verifyActivation(deviceId, activationCode);
        expect(isValid, isTrue);

        // Step 4: Generate logout code
        final logoutCode = EncryptionHelper.generateLogoutCode(deviceId);
        expect(logoutCode.length, 10);

        // All codes should be different
        expect(userCode, isNot(equals(activationCode)));
        expect(activationCode, isNot(equals(logoutCode)));
      });
    });
  });
}
