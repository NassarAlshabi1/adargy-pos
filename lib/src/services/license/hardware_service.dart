import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// خدمة قراءة معلومات الجهاز وإنشاء البصمة الفريدة
class HardwareService {
  static const String _secretKey = 'OFFICE_MGMT_SYSTEM_2024_SECRET';

  /// الحصول على بصمة الجهاز الفريدة
  Future<String> getDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceInfoString = '';

      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceInfoString = '''
        ${windowsInfo.computerName}
        ${windowsInfo.numberOfCores}
        ${windowsInfo.systemMemoryInMegabytes}
        ${windowsInfo.userName}
        ${windowsInfo.majorVersion}
        ${windowsInfo.minorVersion}
        '''
            .trim();
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceInfoString = '''
        ${androidInfo.model}
        ${androidInfo.brand}
        ${androidInfo.device}
        ${androidInfo.hardware}
        ${androidInfo.product}
        ${androidInfo.serialNumber}
        '''
            .trim();
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceInfoString = '''
        ${iosInfo.model}
        ${iosInfo.name}
        ${iosInfo.systemName}
        ${iosInfo.systemVersion}
        ${iosInfo.localizedModel}
        '''
            .trim();
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceInfoString = '''
        ${macInfo.model}
        ${macInfo.computerName}
        ${macInfo.majorVersion}
        ${macInfo.minorVersion}
        ${macInfo.kernelVersion}
        '''
            .trim();
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceInfoString = '''
        ${linuxInfo.name}
        ${linuxInfo.version}
        ${linuxInfo.id}
        ${linuxInfo.machineId}
        '''
            .trim();
      }

      // إنشاء بصمة فريدة من معلومات الجهاز
      final fingerprint = _createFingerprint(deviceInfoString);
      return fingerprint;
    } catch (e) {
      // في حالة فشل قراءة معلومات الجهاز، إنشاء بصمة عشوائية
      return _createFallbackFingerprint();
    }
  }

  /// إنشاء بصمة فريدة من معلومات الجهاز
  String _createFingerprint(String deviceInfo) {
    final combined = '$_secretKey$deviceInfo';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// إنشاء بصمة احتياطية في حالة فشل قراءة معلومات الجهاز
  String _createFallbackFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 1000000).toString().padLeft(6, '0');
    return 'FALLBACK_$random';
  }

  /// التحقق من صحة البصمة
  Future<bool> validateFingerprint(String storedFingerprint) async {
    final currentFingerprint = await getDeviceFingerprint();
    return currentFingerprint == storedFingerprint;
  }

  /// الحصول على معلومات الجهاز للنشر (بدون معلومات حساسة)
  Future<Map<String, String>> getDeviceInfoForDisplay() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return {
          'النوع': 'Windows',
          'الاسم': windowsInfo.computerName,
          'الإصدار': '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          'المعالج': '${windowsInfo.numberOfCores} نواة',
          'الذاكرة': '${windowsInfo.systemMemoryInMegabytes} MB',
        };
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'النوع': 'Android',
          'الموديل': androidInfo.model,
          'الشركة': androidInfo.brand,
          'الإصدار': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'النوع': 'iOS',
          'الموديل': iosInfo.model,
          'الاسم': iosInfo.name,
          'الإصدار': iosInfo.systemVersion,
        };
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return {
          'النوع': 'macOS',
          'الموديل': macInfo.model,
          'الاسم': macInfo.computerName,
          'الإصدار': '${macInfo.majorVersion}.${macInfo.minorVersion}',
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return {
          'النوع': 'Linux',
          'الاسم': linuxInfo.name,
          'الإصدار': linuxInfo.version ?? 'غير محدد',
        };
      }

      return {'النوع': 'غير معروف'};
    } catch (e) {
      return {'النوع': 'خطأ في قراءة المعلومات'};
    }
  }
}
