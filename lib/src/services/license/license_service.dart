import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'hardware_service.dart';

/// خدمة إدارة التراخيص والتحقق من صحة المفاتيح
class LicenseService {
  static const String _licenseKey = 'OFFICE_MGMT_LICENSE';
  static const String _deviceFingerprintKey = 'DEVICE_FINGERPRINT';
  static const String _activationDateKey = 'ACTIVATION_DATE';
  static const String _customerInfoKey = 'CUSTOMER_INFO';
  static const String _trialStartDateKey = 'TRIAL_START_DATE';

  // مدة التجربة بالأيام
  static const int _trialDays = 30;
  static const String _trialFileName = 'trial_store.json';
  static const String _trialFolderName = 'OfficeMgmtSystem';

  // مفتاح التشفير الثابت (يجب تغييره في الإنتاج)
  static const String _encryptionKey =
      'OFFICE_MGMT_2024_ENCRYPTION_KEY_32_CHARS';

  final HardwareService _hardwareService = HardwareService();
  late final Encrypter _encrypter;
  late final IV _iv;

  LicenseService() {
    final key = Key.fromBase64(
        base64.encode(utf8.encode(_encryptionKey)).substring(0, 44));
    _encrypter = Encrypter(AES(key));
    _iv = IV.fromLength(16);
  }

  /// التحقق من حالة الترخيص
  Future<LicenseStatus> checkLicenseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // التحقق من وجود مفتاح الترخيص
      final licenseKey = prefs.getString(_licenseKey);
      if (licenseKey == null || licenseKey.isEmpty) {
        // لا يوجد ترخيص - افحص التجربة المجانية (مقيدة بالبصمة ومحفوظة خارج التطبيق على أجهزة سطح المكتب)
        final trialStartIso = prefs.getString(_trialStartDateKey);
        String? persistentTrialStart;
        String? deviceFingerprint;
        try {
          deviceFingerprint = await _hardwareService.getDeviceFingerprint();
          persistentTrialStart =
              await _readPersistentTrialStart(deviceFingerprint);
        } catch (e) {
          // تجاهل خطأ الحصول على بصمة الجهاز
        }

        // اختر أقدم تاريخ كبداية فعلية للتجربة لتجنب إعادة الضبط
        String? effectiveStart;
        if (persistentTrialStart != null && persistentTrialStart.isNotEmpty) {
          if (trialStartIso != null && trialStartIso.isNotEmpty) {
            final a = DateTime.tryParse(persistentTrialStart);
            final b = DateTime.tryParse(trialStartIso);
            if (a != null && b != null) {
              effectiveStart =
                  a.isBefore(b) ? a.toIso8601String() : b.toIso8601String();
            } else {
              effectiveStart = persistentTrialStart;
            }
          } else {
            effectiveStart = persistentTrialStart;
            // مزامنة إلى SharedPreferences للمرة القادمة
            await prefs.setString(_trialStartDateKey, effectiveStart);
          }
        } else {
          effectiveStart = trialStartIso;
        }

        if (trialStartIso == null || trialStartIso.isEmpty) {
          // بدء التجربة لأول مرة
          final nowIso = DateTime.now().toIso8601String();
          await prefs.setString(_trialStartDateKey, nowIso);
          if (deviceFingerprint != null) {
            await _writePersistentTrialStart(deviceFingerprint, nowIso);
          }
          return LicenseStatus.trialActive;
        } else {
          final start = DateTime.tryParse(effectiveStart ?? trialStartIso);
          if (start == null) {
            // تاريخ غير صالح - إعادة ضبط وبداية تجربة
            final nowIso = DateTime.now().toIso8601String();
            await prefs.setString(_trialStartDateKey, nowIso);
            if (deviceFingerprint != null) {
              await _writePersistentTrialStart(deviceFingerprint, nowIso);
            }
            return LicenseStatus.trialActive;
          }
          final elapsed = DateTime.now().difference(start).inDays;
          if (elapsed < _trialDays) {
            return LicenseStatus.trialActive;
          } else {
            return LicenseStatus.trialExpired;
          }
        }
      }

      // فك تشفير مفتاح الترخيص
      final decryptedLicense = _decryptLicense(licenseKey);
      if (decryptedLicense == null) {
        // إذا فشل فك التشفير، احذف البيانات التالفة
        await _clearPreviousLicense(prefs);
        return LicenseStatus.notActivated;
      }

      // التحقق من صحة المفتاح
      if (!_validateLicenseFormat(decryptedLicense)) {
        // إذا كان المفتاح غير صحيح، احذف البيانات
        await _clearPreviousLicense(prefs);
        return LicenseStatus.notActivated;
      }

      // التحقق من بصمة الجهاز
      final storedFingerprint = prefs.getString(_deviceFingerprintKey);
      if (storedFingerprint == null || storedFingerprint.isEmpty) {
        return LicenseStatus.notActivated;
      }

      final currentFingerprint = await _hardwareService.getDeviceFingerprint();
      if (storedFingerprint != currentFingerprint) {
        // إذا تغيرت بصمة الجهاز، احذف الترخيص القديم
        await _clearPreviousLicense(prefs);
        return LicenseStatus.notActivated;
      }

      return LicenseStatus.valid;
    } catch (e) {
      // في حالة أي خطأ، احذف البيانات وأعد إلى الحالة غير المفعلة
      try {
        final prefs = await SharedPreferences.getInstance();
        await _clearPreviousLicense(prefs);
      } catch (_) {
        // تجاهل الأخطاء في الحذف
      }
      // حتى في حالة الخطأ، حاول السماح بالتجربة إن لم تبدأ
      try {
        final prefs = await SharedPreferences.getInstance();
        final trialStartIso = prefs.getString(_trialStartDateKey);
        if (trialStartIso == null || trialStartIso.isEmpty) {
          // حاول قراءة مخزن التجربة الدائم قبل البدء
          try {
            final fp = await _hardwareService.getDeviceFingerprint();
            final persistent = await _readPersistentTrialStart(fp);
            if (persistent != null && persistent.isNotEmpty) {
              await prefs.setString(_trialStartDateKey, persistent);
              final start = DateTime.tryParse(persistent);
              if (start != null &&
                  DateTime.now().difference(start).inDays < _trialDays) {
                return LicenseStatus.trialActive;
              }
              return LicenseStatus.trialExpired;
            }
          } catch (e) {
            // تجاهل خطأ قراءة تاريخ بداية التجربة
          }
          final nowIso = DateTime.now().toIso8601String();
          await prefs.setString(_trialStartDateKey, nowIso);
          return LicenseStatus.trialActive;
        }
      } catch (e) {
        // تجاهل خطأ التحقق من حالة الترخيص
      }
      return LicenseStatus.trialExpired;
    }
  }

  /// تفعيل الترخيص
  Future<ActivationResult> activateLicense(String licenseKey) async {
    try {
      // التحقق من صحة تنسيق المفتاح
      if (!_validateLicenseFormat(licenseKey)) {
        return ActivationResult(
          success: false,
          message:
              'تنسيق مفتاح الترخيص غير صحيح. تأكد من كتابة المفتاح بالشكل الصحيح.',
        );
      }

      // الحصول على بصمة الجهاز الحالية
      final deviceFingerprint = await _hardwareService.getDeviceFingerprint();

      // حفظ الترخيص في التخزين المحلي
      final prefs = await SharedPreferences.getInstance();

      // إلغاء أي ترخيص سابق قبل التفعيل الجديد
      await _clearPreviousLicense(prefs);

      // تشفير وحفظ مفتاح الترخيص
      final encryptedLicense = _encryptLicense(licenseKey);
      await prefs.setString(_licenseKey, encryptedLicense);

      // حفظ بصمة الجهاز
      await prefs.setString(_deviceFingerprintKey, deviceFingerprint);

      // حفظ تاريخ التفعيل
      await prefs.setString(
          _activationDateKey, DateTime.now().toIso8601String());

      return ActivationResult(
        success: true,
        message: 'تم تفعيل الترخيص بنجاح. يمكنك الآن استخدام التطبيق.',
        deviceFingerprint: deviceFingerprint,
      );
    } catch (e) {
      return ActivationResult(
        success: false,
        message:
            'خطأ في تفعيل الترخيص. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.',
      );
    }
  }

  // ===================== دعم تخزين تجربة دائم على سطح المكتب =====================
  Future<File?> _getPersistentTrialFile() async {
    try {
      if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        return null; // المنصات المحمولة تعتمد على SharedPreferences فقط
      }

      String? baseDir;
      if (Platform.isWindows) {
        baseDir = Platform.environment['APPDATA'] ??
            Platform.environment['LOCALAPPDATA'];
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        baseDir = home != null ? '$home/Library/Application Support' : null;
      } else if (Platform.isLinux) {
        final xdg = Platform.environment['XDG_CONFIG_HOME'];
        if (xdg != null && xdg.isNotEmpty) {
          baseDir = xdg;
        } else {
          final home = Platform.environment['HOME'];
          baseDir = home != null ? '$home/.config' : null;
        }
      }

      if (baseDir == null) return null;

      final folderPath = Platform.isWindows
          ? '$baseDir\\$_trialFolderName'
          : '$baseDir/$_trialFolderName';
      final filePath = Platform.isWindows
          ? '$folderPath\\$_trialFileName'
          : '$folderPath/$_trialFileName';

      final dir = Directory(folderPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File(filePath);
      if (!await file.exists()) {
        await file.create();
        await file.writeAsString(jsonEncode({}));
      }
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _readPersistentTrialStart(String fingerprint) async {
    try {
      final file = await _getPersistentTrialFile();
      if (file == null) return null;
      final content = await file.readAsString();
      if (content.isEmpty) return null;
      final data = jsonDecode(content);
      if (data is Map<String, dynamic>) {
        final v = data[fingerprint];
        if (v is String) return v;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistentTrialStart(
      String fingerprint, String isoDate) async {
    try {
      final file = await _getPersistentTrialFile();
      if (file == null) return;
      Map<String, dynamic> data = {};
      try {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final parsed = jsonDecode(content);
          if (parsed is Map<String, dynamic>) {
            data = parsed;
          }
        }
      } catch (e) {
        // تجاهل خطأ قراءة ملف التجربة
      }
      // احتفظ بأقدم تاريخ إن وجد
      if (data.containsKey(fingerprint)) {
        final existing = DateTime.tryParse(data[fingerprint] as String? ?? '');
        final incoming = DateTime.tryParse(isoDate);
        if (existing != null && incoming != null) {
          data[fingerprint] = existing.isBefore(incoming)
              ? existing.toIso8601String()
              : incoming.toIso8601String();
        } else {
          data[fingerprint] = isoDate;
        }
      } else {
        data[fingerprint] = isoDate;
      }
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // تجاهل أخطاء الكتابة
    }
  }

  /// إلغاء تفعيل الترخيص
  Future<bool> deactivateLicense() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearPreviousLicense(prefs);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// حذف الترخيص السابق
  Future<void> _clearPreviousLicense(SharedPreferences prefs) async {
    await prefs.remove(_licenseKey);
    await prefs.remove(_deviceFingerprintKey);
    await prefs.remove(_activationDateKey);
    await prefs.remove(_customerInfoKey);
    // لا تزل مفتاح بداية التجربة حتى لا يعاد ضبطها
  }

  /// الحصول على معلومات الترخيص
  Future<LicenseInfo?> getLicenseInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final licenseKey = prefs.getString(_licenseKey);
      if (licenseKey == null || licenseKey.isEmpty) {
        return null;
      }

      final decryptedLicense = _decryptLicense(licenseKey);
      if (decryptedLicense == null) {
        return null;
      }

      final deviceFingerprint = prefs.getString(_deviceFingerprintKey) ?? '';
      final activationDate = prefs.getString(_activationDateKey) ?? '';
      final customerInfo = prefs.getString(_customerInfoKey) ?? '';

      return LicenseInfo(
        licenseKey: decryptedLicense,
        deviceFingerprint: deviceFingerprint,
        activationDate: activationDate,
        customerInfo: customerInfo,
      );
    } catch (e) {
      return null;
    }
  }

  /// الحصول على عدد الأيام المتبقية في التجربة
  Future<int> getTrialDaysLeft() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartIso = prefs.getString(_trialStartDateKey);
    if (trialStartIso == null || trialStartIso.isEmpty) return _trialDays;
    final start = DateTime.tryParse(trialStartIso);
    if (start == null) return _trialDays;
    final elapsed = DateTime.now().difference(start).inDays;
    final remaining = _trialDays - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// حفظ معلومات العميل
  Future<void> saveCustomerInfo(
      String customerName, String customerContact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerInfo = jsonEncode({
        'name': customerName,
        'contact': customerContact,
        'date': DateTime.now().toIso8601String(),
      });
      await prefs.setString(_customerInfoKey, customerInfo);
    } catch (e) {
      // تجاهل الأخطاء في حفظ معلومات العميل
    }
  }

  /// تشفير مفتاح الترخيص
  String _encryptLicense(String licenseKey) {
    try {
      final encrypted = _encrypter.encrypt(licenseKey, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      return licenseKey; // إرجاع المفتاح غير مشفر في حالة الخطأ
    }
  }

  /// فك تشفير مفتاح الترخيص
  String? _decryptLicense(String encryptedLicense) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedLicense);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      // محاولة استخدام المفتاح كما هو (في حالة عدم وجود تشفير)
      try {
        if (_validateLicenseFormat(encryptedLicense)) {
          return encryptedLicense;
        }
      } catch (e) {
        // تجاهل الأخطاء
      }
      return null;
    }
  }

  /// التحقق من صحة تنسيق مفتاح الترخيص
  bool _validateLicenseFormat(String licenseKey) {
    if (licenseKey.isEmpty) return false;

    // تنظيف المفتاح من المسافات والأحرف غير المرغوبة
    final cleanKey = licenseKey.toUpperCase().trim();

    // التحقق من البادئة
    if (!cleanKey.startsWith('OFFICE-')) {
      return false;
    }

    // تنسيق المفتاح: OFFICE-YYYY-XXXXXX-XXXXXXXX
    // تنسيقات مقبولة للإنتاج - أكثر مرونة
    final patterns = [
      RegExp(r'^OFFICE-\d{4}-[A-Z0-9]{6}-[A-Z0-9]{8}$'), // التنسيق الكامل
      RegExp(r'^OFFICE-\d{4}-[A-Z0-9]{6}-[A-Z0-9]{6}$'), // تنسيق مختصر
      RegExp(r'^OFFICE-\d{4}-[A-Z0-9]{3}-[A-Z0-9]{6}$'), // تنسيق آخر
      RegExp(r'^OFFICE-\d{4}-[A-Z0-9]{4}-[A-Z0-9]{6}$'), // تنسيق إنتاج
      RegExp(r'^OFFICE-\d{4}-[A-Z0-9]{5}-[A-Z0-9]{7}$'), // تنسيق إضافي
      RegExp(r'^OFFICE-\d{4}-[A-Z0-9]{7}-[A-Z0-9]{8}$'), // تنسيق إضافي
    ];

    // التحقق من التنسيق
    if (!patterns.any((pattern) => pattern.hasMatch(cleanKey))) {
      return false;
    }

    // التحقق من السنة (يجب أن تكون 2024 أو أحدث - أكثر مرونة)
    final yearMatch = RegExp(r'^OFFICE-(\d{4})-').firstMatch(cleanKey);
    if (yearMatch != null) {
      final year = int.tryParse(yearMatch.group(1) ?? '');
      if (year != null && year >= 2024) {
        return true;
      }
    }

    return false;
  }

  /// إنشاء مفتاح ترخيص جديد (للمطور فقط)
  static String generateLicenseKey({String? customPrefix}) {
    final now = DateTime.now();
    final year = now.year.toString();
    final random1 = _generateRandomString(6);
    final random2 = _generateRandomString(8);
    final prefix = customPrefix ?? 'OFFICE';
    return '$prefix-$year-$random1-$random2';
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
}

/// حالة الترخيص
enum LicenseStatus {
  valid, // الترخيص صحيح ومفعل
  notActivated, // لم يتم تفعيل الترخيص
  invalid, // مفتاح الترخيص غير صحيح
  deviceMismatch, // الجهاز لا يطابق الترخيص
  error, // خطأ في التحقق
  trialActive, // تجربة مجانية نشطة
  trialExpired, // انتهت الفترة التجريبية
}

/// نتيجة التفعيل
class ActivationResult {
  final bool success;
  final String message;
  final String? deviceFingerprint;

  ActivationResult({
    required this.success,
    required this.message,
    this.deviceFingerprint,
  });
}

/// معلومات الترخيص
class LicenseInfo {
  final String licenseKey;
  final String deviceFingerprint;
  final String activationDate;
  final String customerInfo;

  LicenseInfo({
    required this.licenseKey,
    required this.deviceFingerprint,
    required this.activationDate,
    required this.customerInfo,
  });
}
