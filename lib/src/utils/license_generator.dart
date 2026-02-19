import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// أداة إنشاء مفاتيح الترخيص للمطور
class LicenseGenerator {
  static const String _prefix = 'OFFICE';
  static const String _secretKey = 'OFFICE_MGMT_SYSTEM_2024_SECRET';

  /// إنشاء مفتاح ترخيص جديد
  static String generateLicenseKey({
    String? customPrefix,
    String? customerName,
    DateTime? expirationDate,
  }) {
    final now = DateTime.now();
    final year = now.year.toString();
    final prefix = customPrefix ?? _prefix;

    // إنشاء جزء عشوائي
    final randomPart1 = _generateRandomString(6);
    final randomPart2 = _generateRandomString(8);

    // إنشاء المفتاح الأساسي
    String licenseKey = '$prefix-$year-$randomPart1-$randomPart2';

    // إضافة معلومات إضافية إذا تم توفيرها
    if (customerName != null || expirationDate != null) {
      final extraInfo = <String>[];

      if (customerName != null) {
        extraInfo.add('CUST:${_encodeCustomerName(customerName)}');
      }

      if (expirationDate != null) {
        extraInfo.add('EXP:${expirationDate.millisecondsSinceEpoch}');
      }

      if (extraInfo.isNotEmpty) {
        final extraString = extraInfo.join('-');
        final checksum = _generateChecksum('$licenseKey-$extraString');
        licenseKey = '$licenseKey-$extraString-CHK:$checksum';
      }
    }

    return licenseKey;
  }

  /// إنشاء نص عشوائي
  static String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }

    return buffer.toString();
  }

  /// تشفير اسم العميل
  static String _encodeCustomerName(String customerName) {
    final bytes = utf8.encode(customerName);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  /// إنشاء checksum للمفتاح
  static String _generateChecksum(String key) {
    final combined = '$_secretKey$key';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 6).toUpperCase();
  }

  /// التحقق من صحة مفتاح الترخيص
  static bool validateLicenseKey(String licenseKey) {
    try {
      // التحقق من التنسيق الأساسي
      if (!licenseKey.toUpperCase().startsWith('OFFICE-')) {
        return false;
      }

      // تقسيم المفتاح إلى أجزاء
      final parts = licenseKey.split('-');
      if (parts.length < 4) {
        return false;
      }

      // التحقق من الجزء الأول (البادئة)
      if (parts[0].toUpperCase() != 'OFFICE') {
        return false;
      }

      // التحقق من السنة
      final year = int.tryParse(parts[1]);
      if (year == null || year < 2024 || year > 2030) {
        return false;
      }

      // التحقق من الجزء العشوائي الأول
      if (parts[2].length != 6) {
        return false;
      }

      // التحقق من الجزء العشوائي الثاني
      if (parts[3].length != 8) {
        return false;
      }

      // إذا كان هناك checksum، التحقق منه
      if (parts.length > 4) {
        final checksumPart = parts.last;
        if (checksumPart.startsWith('CHK:')) {
          final providedChecksum = checksumPart.substring(4);
          final baseKey = parts.sublist(0, parts.length - 1).join('-');
          final expectedChecksum = _generateChecksum(baseKey);

          if (providedChecksum != expectedChecksum) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// استخراج معلومات من مفتاح الترخيص
  static Map<String, dynamic> parseLicenseKey(String licenseKey) {
    final result = <String, dynamic>{
      'valid': false,
      'prefix': '',
      'year': null,
      'customerName': null,
      'expirationDate': null,
    };

    try {
      if (!validateLicenseKey(licenseKey)) {
        return result;
      }

      final parts = licenseKey.split('-');

      result['valid'] = true;
      result['prefix'] = parts[0];
      result['year'] = int.tryParse(parts[1]);

      // البحث عن معلومات العميل
      for (final part in parts) {
        if (part.startsWith('CUST:')) {
          result['customerName'] = part.substring(5);
        } else if (part.startsWith('EXP:')) {
          final timestamp = int.tryParse(part.substring(4));
          if (timestamp != null) {
            result['expirationDate'] =
                DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }
      }

      return result;
    } catch (e) {
      return result;
    }
  }

  /// إنشاء دفعة من مفاتيح الترخيص
  static List<String> generateBatch({
    int count = 10,
    String? customPrefix,
    String? customerPrefix,
  }) {
    final licenses = <String>[];

    for (int i = 0; i < count; i++) {
      final customerName = customerPrefix != null
          ? '$customerPrefix-${(i + 1).toString().padLeft(3, '0')}'
          : null;

      final license = generateLicenseKey(
        customPrefix: customPrefix,
        customerName: customerName,
      );

      licenses.add(license);
    }

    return licenses;
  }

  /// طباعة معلومات مفتاح الترخيص
  static void printLicenseInfo(String licenseKey) {
    final info = parseLicenseKey(licenseKey);

    if (kDebugMode) {
      debugPrint('=== معلومات مفتاح الترخيص ===');
      debugPrint('المفتاح: $licenseKey');
      debugPrint('صحيح: ${info['valid']}');
      debugPrint('البادئة: ${info['prefix']}');
      debugPrint('السنة: ${info['year']}');
      debugPrint('اسم العميل: ${info['customerName'] ?? 'غير محدد'}');
      debugPrint('تاريخ الانتهاء: ${info['expirationDate'] ?? 'غير محدد'}');
      debugPrint('==============================');
    }
  }
}

/// أداة مساعدة لإنشاء مفاتيح الترخيص من سطر الأوامر
class LicenseGeneratorCLI {
  /// إنشاء مفتاح ترخيص واحد
  static void generateSingle() {
    final license = LicenseGenerator.generateLicenseKey();
    if (kDebugMode) {
      debugPrint('مفتاح الترخيص الجديد: $license');
    }
    LicenseGenerator.printLicenseInfo(license);
  }

  /// إنشاء دفعة من مفاتيح الترخيص
  static void generateBatch({int count = 10, String? customerPrefix}) {
    final licenses = LicenseGenerator.generateBatch(
      count: count,
      customerPrefix: customerPrefix,
    );

    if (kDebugMode) {
      debugPrint('=== دفعة مفاتيح الترخيص ($count) ===');
      for (int i = 0; i < licenses.length; i++) {
        debugPrint('${i + 1}. ${licenses[i]}');
      }
      debugPrint('================================');
    }
  }

  /// التحقق من مفتاح ترخيص
  static void validate(String licenseKey) {
    LicenseGenerator.printLicenseInfo(licenseKey);
  }
}
