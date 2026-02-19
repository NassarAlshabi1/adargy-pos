import 'package:flutter/foundation.dart';
import '../config/store_info.dart';
import 'store_info_service.dart';

class StoreConfig extends ChangeNotifier {
  // معلومات التطبيق (ثابتة - لا تتغير)
  String get appTitle => StoreInfo.appTitle;
  String get displayVersion => StoreInfo.displayVersion;
  String? get logoAssetPath => StoreInfo.logoAssetPath;
  String get developer => StoreInfo.developer;
  String get language => StoreInfo.language;
  String get releaseYear => StoreInfo.releaseYear;

  // معلومات المحل (قابلة للتعديل من داخل التطبيق)
  // نستخدم StoreInfoService أولاً، وإذا لم تكن موجودة نستخدم القيم الافتراضية
  String _shopName = StoreInfo.shopName;
  String _shopDescription = StoreInfo.shopDescription;
  String _phone = StoreInfo.phone;
  String _address = StoreInfo.address;
  final String _email = StoreInfo.email;
  final String _whatsapp = StoreInfo.whatsapp;
  final String _city = StoreInfo.city;
  final String _country = StoreInfo.country;

  String get shopName => _shopName;
  String get shopDescription => _shopDescription;
  String get phone => _phone;
  String get address => _address;
  String get email => _email;
  String get whatsapp => _whatsapp;
  String get city => _city;
  String get country => _country;

  // معلومات الدعم (ثابتة - خاصة بالمطور)
  String get supportPhone => StoreInfo.supportPhone;
  String get supportEmail => StoreInfo.supportEmail;
  String get supportAddress => StoreInfo.supportAddress;

  // معلومات قانونية (ثابتة)
  String get copyright => StoreInfo.copyright;
  String get rightsReserved => StoreInfo.rightsReserved;
  String get ownership => StoreInfo.ownership;

  // تحميل معلومات المحل من SharedPreferences
  Future<void> initialize() async {
    await _loadStoreInfo();
    notifyListeners();
  }

  // تحميل معلومات المحل المحفوظة
  Future<void> _loadStoreInfo() async {
    try {
      final storeInfo = await StoreInfoService.getStoreInfo();
      if (storeInfo != null && storeInfo.isValid) {
        // استخدام المعلومات المحفوظة
        _shopName = storeInfo.storeName;
        _address = storeInfo.address;
        _phone = storeInfo.phone;
        _shopDescription = storeInfo.description;
        // البريد والواتساب والمدينة والدولة تبقى من القيم الافتراضية
        // (يمكن إضافتها لاحقاً إلى StoreInfo model إذا لزم الأمر)
      }
      // إذا لم تكن هناك معلومات محفوظة، نستخدم القيم الافتراضية
    } catch (e) {
      // في حالة الخطأ، نستخدم القيم الافتراضية
    }
  }

  // تحديث معلومات المحل (يُستدعى عند تغيير المعلومات)
  Future<void> refreshStoreInfo() async {
    await _loadStoreInfo();
    notifyListeners();
  }
}
