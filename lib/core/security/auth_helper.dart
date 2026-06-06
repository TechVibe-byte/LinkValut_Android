import 'package:local_auth/local_auth.dart';
import '../database/hive_helper.dart';

class AuthHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _pinEnabledKey = "pin_enabled";
  static const String _pinCodeKey = "pin_code";
  static const String _biometricEnabledKey = "biometric_enabled";

  static bool get isPinEnabled => HiveHelper.settingsBox.get(_pinEnabledKey, defaultValue: false) as bool;
  
  static String? get savedPin => HiveHelper.settingsBox.get(_pinCodeKey) as String?;

  static bool get isBiometricEnabled => HiveHelper.settingsBox.get(_biometricEnabledKey, defaultValue: false) as bool;

  static Future<void> enablePin(String pin) async {
    await HiveHelper.settingsBox.put(_pinEnabledKey, true);
    await HiveHelper.settingsBox.put(_pinCodeKey, pin);
  }

  static Future<void> disablePin() async {
    await HiveHelper.settingsBox.put(_pinEnabledKey, false);
    await HiveHelper.settingsBox.delete(_pinCodeKey);
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await HiveHelper.settingsBox.put(_biometricEnabledKey, enabled);
  }

  static Future<bool> canUseBiometrics() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  static Future<bool> authenticateBiometrically() async {
    try {
      if (!await canUseBiometrics()) return false;
      return await _auth.authenticate(
        localizedReason: 'Scan biometrics to unlock LinkVault',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      return false;
    }
  }
}
