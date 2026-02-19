import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/database_service.dart';

/// خدمة النسخ الاحتياطي التلقائي
/// تقوم بإنشاء نسخ احتياطية تلقائية حسب الجدولة المحددة
class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  Timer? _backupTimer;
  DatabaseService? _databaseService;
  bool _isRunning = false;

  /// تهيئة الخدمة
  Future<void> initialize(DatabaseService databaseService) async {
    _databaseService = databaseService;
    await _startAutoBackup();
  }

  /// بدء النسخ الاحتياطي التلقائي
  Future<void> _startAutoBackup() async {
    if (_isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;

    if (!autoBackupEnabled) {
      return;
    }

    _isRunning = true;

    // التحقق من النسخ الاحتياطي عند بدء التطبيق
    await _checkAndRunBackup();

    // إعداد Timer للتحقق الدوري كل ساعة
    _backupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkAndRunBackup(),
    );
  }

  /// التحقق من الحاجة للنسخ الاحتياطي وتشغيله
  Future<void> _checkAndRunBackup() async {
    try {
      if (_databaseService == null) return;

      final prefs = await SharedPreferences.getInstance();
      final autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      final backupPath = prefs.getString('backup_path') ?? '';

      if (!autoBackupEnabled || backupPath.isEmpty) {
        return;
      }

      final autoBackupFrequency =
          prefs.getString('auto_backup_frequency') ?? 'weekly';

      // التحقق من موعد آخر نسخة احتياطية
      final lastBackupTime = prefs.getInt('last_auto_backup_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastBackup = now - lastBackupTime;

      bool shouldBackup = false;
      int requiredInterval = 0;

      switch (autoBackupFrequency) {
        case 'hourly':
          requiredInterval = 60 * 60 * 1000; // ساعة واحدة
          shouldBackup = timeSinceLastBackup >= requiredInterval;
          break;
        case 'daily':
          requiredInterval = 24 * 60 * 60 * 1000; // 24 ساعة
          shouldBackup = timeSinceLastBackup >= requiredInterval;
          break;
        case 'weekly':
          requiredInterval = 7 * 24 * 60 * 60 * 1000; // 7 أيام
          shouldBackup = timeSinceLastBackup >= requiredInterval;
          break;
        case 'monthly':
          requiredInterval = 30 * 24 * 60 * 60 * 1000; // 30 يوم
          shouldBackup = timeSinceLastBackup >= requiredInterval;
          break;
      }

      if (shouldBackup) {
        try {
          await _databaseService!.createFullBackup(backupPath);
          await prefs.setInt('last_auto_backup_time', now);
          await prefs.setString('last_auto_backup_status', 'success');
          await prefs.setString(
              'last_auto_backup_message', 'تم إنشاء النسخة الاحتياطية بنجاح');
        } catch (e) {
          await prefs.setString('last_auto_backup_status', 'error');
          await prefs.setString(
              'last_auto_backup_message', 'فشل في إنشاء النسخة الاحتياطية: $e');
        }
      }
    } catch (e) {
      // تجاهل خطأ التحقق من النسخ الاحتياطي
    }
  }

  /// إعادة تشغيل الخدمة (عند تغيير الإعدادات)
  Future<void> restart() async {
    stop();
    await _startAutoBackup();
  }

  /// إيقاف الخدمة
  void stop() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _isRunning = false;
  }

  /// الحصول على حالة الخدمة
  bool get isRunning => _isRunning;

  /// الحصول على معلومات آخر نسخة احتياطية
  Future<Map<String, dynamic>> getLastBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupTime = prefs.getInt('last_auto_backup_time') ?? 0;
    final status = prefs.getString('last_auto_backup_status') ?? 'unknown';
    final message = prefs.getString('last_auto_backup_message') ?? '';

    return {
      'lastBackupTime': lastBackupTime,
      'lastBackupDate': lastBackupTime > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupTime)
          : null,
      'status': status,
      'message': message,
      'isEnabled': prefs.getBool('auto_backup_enabled') ?? false,
      'frequency': prefs.getString('auto_backup_frequency') ?? 'weekly',
    };
  }

  /// إنشاء نسخة احتياطية يدوية فورية
  Future<String?> createManualBackup() async {
    try {
      if (_databaseService == null) {
        throw Exception('خدمة قاعدة البيانات غير متاحة');
      }

      final prefs = await SharedPreferences.getInstance();
      final backupPath = prefs.getString('backup_path') ?? '';

      if (backupPath.isEmpty) {
        throw Exception('مسار النسخ الاحتياطي غير محدد');
      }

      final backupFilePath =
          await _databaseService!.createFullBackup(backupPath);
      final now = DateTime.now().millisecondsSinceEpoch;

      await prefs.setInt('last_auto_backup_time', now);
      await prefs.setString('last_auto_backup_status', 'success');
      await prefs.setString('last_auto_backup_message',
          'تم إنشاء النسخة الاحتياطية يدوياً بنجاح');

      return backupFilePath;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_auto_backup_status', 'error');
      await prefs.setString(
          'last_auto_backup_message', 'فشل في إنشاء النسخة الاحتياطية: $e');

      rethrow;
    }
  }

  /// تنظيف الموارد
  void dispose() {
    stop();
  }
}
