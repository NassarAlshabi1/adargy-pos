/// نموذج بيانات معلومات المتجر (مبسط)
class StoreInfo {
  final String? id;
  final String storeName; // اسم المحل
  final String address; // العنوان
  final String phone; // رقم الهاتف
  final String description; // الوصف
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreInfo({
    this.id,
    required this.storeName,
    required this.address,
    required this.phone,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// إنشاء نسخة من الكائن مع تحديث بعض الحقول
  StoreInfo copyWith({
    String? id,
    String? storeName,
    String? address,
    String? phone,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoreInfo(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تحويل الكائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'store_name': storeName,
      'address': address,
      'phone': phone,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء كائن من Map
  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      id: map['id']?.toString(),
      storeName: map['store_name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// إنشاء كائن فارغ مع القيم الافتراضية
  factory StoreInfo.empty() {
    final now = DateTime.now();
    return StoreInfo(
      storeName: 'اسم المحل',
      address: 'العنوان',
      phone: 'رقم الهاتف',
      description: 'وصف المحل',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// التحقق من صحة البيانات
  bool get isValid {
    return storeName.isNotEmpty &&
        address.isNotEmpty &&
        phone.isNotEmpty &&
        description.isNotEmpty;
  }

  /// الحصول على معلومات المتجر للطباعة
  Map<String, String> getPrintInfo() {
    return {
      'store_name': storeName,
      'address': address,
      'phone': phone,
      'description': description,
    };
  }

  /// الحصول على معلومات المتجر للعرض
  Map<String, String> getDisplayInfo() {
    return {
      'اسم المحل': storeName,
      'العنوان': address,
      'الهاتف': phone,
      'الوصف': description,
    };
  }

  @override
  String toString() {
    return 'StoreInfo(id: $id, storeName: $storeName, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreInfo &&
        other.id == id &&
        other.storeName == storeName &&
        other.address == address;
  }

  @override
  int get hashCode {
    return id.hashCode ^ storeName.hashCode ^ address.hashCode;
  }
}
