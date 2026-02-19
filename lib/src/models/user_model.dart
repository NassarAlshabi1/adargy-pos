/// نموذج بيانات المستخدم مع نظام الصلاحيات
class UserModel {
  final int? id;
  final String name; // الاسم الكامل
  final String username; // اسم المستخدم
  final String password; // كلمة المرور
  final UserRole? role; // دور المستخدم (legacy - للتوافق مع النظام القديم)
  final int? groupId; // معرف المجموعة
  final String employeeCode; // رمز الموظف
  final bool active; // حالة المستخدم
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    this.id,
    required this.name,
    required this.username,
    required this.password,
    this.role,
    this.groupId,
    required this.employeeCode,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// إنشاء نسخة من الكائن مع تحديث بعض الحقول
  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? password,
    UserRole? role,
    int? groupId,
    String? employeeCode,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      groupId: groupId ?? this.groupId,
      employeeCode: employeeCode ?? this.employeeCode,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تحويل الكائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'role': role?.name, // legacy support
      'group_id': groupId,
      'employee_code': employeeCode,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء كائن من Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] != null ? UserRole.fromString(map['role']) : null,
      groupId: map['group_id']?.toInt(),
      employeeCode: map['employee_code'] ?? '',
      active: (map['active'] ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// الحصول على اسم الدور بالعربية (legacy support)
  String get roleDisplayName => role?.displayName ?? 'غير محدد';

  /// الحصول على وصف الصلاحيات (legacy support)
  String get permissionsDescription => role?.permissionsDescription ?? '';

  /// التحقق من وجود صلاحية معينة
  /// Note: يجب تمرير GroupModel عند استخدام نظام المجموعات
  bool hasPermission(UserPermission permission, {GroupModel? group}) {
    if (group != null) {
      return group.hasPermission(permission);
    }
    // Legacy support: check role permissions
    if (role != null) {
      return role!.permissions.contains(permission);
    }
    return false;
  }

  /// التحقق من صحة البيانات
  bool get isValid {
    return name.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        employeeCode.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, username: $username, role: $role, employeeCode: $employeeCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.username == username &&
        other.employeeCode == employeeCode;
  }

  @override
  int get hashCode {
    return id.hashCode ^ username.hashCode ^ employeeCode.hashCode;
  }
}

/// أدوار المستخدمين
enum UserRole {
  manager('manager', 'مدير', [
    // إدارة المستخدمين والنظام
    UserPermission.manageUsers,
    UserPermission.systemSettings,
    UserPermission.manageBackup,
    UserPermission.manageLicensing,

    // المبيعات
    UserPermission.manageSales,
    UserPermission.applyDiscount,
    UserPermission.overridePrice,
    UserPermission.refundSales,
    UserPermission.voidSale,
    UserPermission.deleteSaleItem,
    UserPermission.openCashDrawer,

    // المخزون والمنتجات
    UserPermission.manageProducts,
    UserPermission.manageInventory,
    UserPermission.adjustStock,
    UserPermission.viewCostPrice,
    UserPermission.editCostPrice,
    UserPermission.receivePurchase,
    UserPermission.manageSuppliers,
    UserPermission.manageCategories,
    UserPermission.manageCustomers,

    // التقارير
    UserPermission.viewReports,
    UserPermission.exportReports,
    UserPermission.viewProfitCosts,
  ]),
  supervisor('supervisor', 'مشرف', [
    // المبيعات
    UserPermission.manageSales,
    UserPermission.applyDiscount,
    UserPermission.refundSales,

    // المخزون والمنتجات
    UserPermission.manageProducts,
    UserPermission.manageInventory,
    UserPermission.adjustStock,
    UserPermission.viewCostPrice,
    UserPermission.receivePurchase,
    UserPermission.manageSuppliers,
    UserPermission.manageCategories,
    UserPermission.manageCustomers,

    // التقارير
    UserPermission.viewReports,
    UserPermission.exportReports,
  ]),
  employee('employee', 'موظف', [
    // المبيعات
    UserPermission.manageSales,

    // التقارير
    UserPermission.viewReports,
  ]);

  const UserRole(this.value, this.displayName, this.permissions);

  final String value;
  final String displayName;
  final List<UserPermission> permissions;

  /// إنشاء دور من نص
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'manager':
        return UserRole.manager;
      case 'supervisor':
        return UserRole.supervisor;
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }

  /// الحصول على وصف الصلاحيات
  String get permissionsDescription {
    switch (this) {
      case UserRole.manager:
        return 'جميع الصلاحيات - مستخدمون، نظام، مبيعات، مخزون، تقارير، مزودين، تصنيفات، أسعار وتكاليف، شراء واستلام، خصومات واسترجاع وإلغاء فواتير، نسخ احتياطي وترخيص';
      case UserRole.supervisor:
        return 'صلاحيات واسعة عدا إدارة المستخدمين وإعدادات النظام الكاملة: مبيعات، مخزون، منتجات، مزودين، تصنيفات، استلام شراء، عرض التكاليف، تصدير التقارير';
      case UserRole.employee:
        return 'المبيعات الأساسية وعرض التقارير';
    }
  }
}

/// صلاحيات المستخدمين
enum UserPermission {
  // نظام ومستخدمون
  manageUsers('إدارة المستخدمين'),
  systemSettings('إعدادات النظام'),
  manageBackup('إدارة النسخ الاحتياطي'),
  manageLicensing('إدارة الترخيص'),

  // مبيعات
  manageSales('إدارة المبيعات'),
  applyDiscount('تطبيق الخصومات'),
  overridePrice('تجاوز السعر'),
  refundSales('مرتجعات المبيعات'),
  voidSale('إلغاء الفاتورة'),
  deleteSaleItem('حذف صنف من الفاتورة'),
  openCashDrawer('فتح درج النقدية'),

  // تقارير
  viewReports('عرض التقارير'),
  exportReports('تصدير التقارير'),
  viewProfitCosts('عرض الأرباح والتكاليف'),

  // مخزون ومنتجات وموردين
  manageProducts('إدارة المنتجات'),
  manageInventory('إدارة المخزون'),
  adjustStock('تعديل المخزون'),
  viewCostPrice('عرض سعر الكلفة'),
  editCostPrice('تعديل سعر الكلفة'),
  receivePurchase('استلام شراء'),
  manageSuppliers('إدارة الموردين'),
  manageCategories('إدارة التصنيفات'),
  manageCustomers('إدارة العملاء');

  const UserPermission(this.displayName);

  final String displayName;
}

/// بيانات المستخدمين الافتراضية
class DefaultUsers {
  static const List<Map<String, dynamic>> users = [
    {
      'name': 'المدير',
      'username': 'manager',
      // لا نخزن كلمة مرور واضحة هنا
      'role': 'manager',
      'employee_code': 'A1',
    },
    {
      'name': 'المشرف',
      'username': 'supervisor',
      // لا نخزن كلمة مرور واضحة هنا
      'role': 'supervisor',
      'employee_code': 'S1',
    },
    {
      'name': 'الموظف',
      'username': 'employee',
      // لا نخزن كلمة مرور واضحة هنا
      'role': 'employee',
      'employee_code': 'C1',
    },
  ];

  /// الحصول على بيانات المستخدمين للقاعدة
  static List<Map<String, dynamic>> getUsersForDatabase() {
    final now = DateTime.now();
    return users.map((user) {
      return {
        ...user,
        'active': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
    }).toList();
  }
}

/// الأقسام المختلفة في النظام
enum SystemSection {
  finance('finance', 'المالية'),
  hr('hr', 'الموارد البشرية'),
  sales('sales', 'المبيعات'),
  inventory('inventory', 'المخزون'),
  reports('reports', 'التقارير'),
  system('system', 'النظام');

  const SystemSection(this.value, this.displayName);

  final String value;
  final String displayName;

  static SystemSection fromString(String value) {
    switch (value.toLowerCase()) {
      case 'finance':
        return SystemSection.finance;
      case 'hr':
        return SystemSection.hr;
      case 'sales':
        return SystemSection.sales;
      case 'inventory':
        return SystemSection.inventory;
      case 'reports':
        return SystemSection.reports;
      case 'system':
        return SystemSection.system;
      default:
        return SystemSection.system;
    }
  }
}

/// نموذج المجموعة
class GroupModel {
  final int? id;
  final String name; // اسم المجموعة
  final String? description; // وصف المجموعة
  final bool active; // حالة المجموعة
  final DateTime createdAt;
  final DateTime updatedAt;

  // الصلاحيات حسب الأقسام
  final Map<SystemSection, List<UserPermission>> permissions;

  const GroupModel({
    this.id,
    required this.name,
    this.description,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
    this.permissions = const {},
  });

  /// إنشاء نسخة من الكائن مع تحديث بعض الحقول
  GroupModel copyWith({
    int? id,
    String? name,
    String? description,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<SystemSection, List<UserPermission>>? permissions,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      permissions: permissions ?? this.permissions,
    );
  }

  /// تحويل الكائن إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء كائن من Map
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'],
      active: (map['active'] ?? 1) == 1,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// التحقق من وجود صلاحية معينة
  bool hasPermission(UserPermission permission) {
    for (final sectionPermissions in permissions.values) {
      if (sectionPermissions.contains(permission)) {
        return true;
      }
    }
    return false;
  }

  /// التحقق من وجود صلاحية في قسم معين
  bool hasPermissionInSection(
      UserPermission permission, SystemSection section) {
    return permissions[section]?.contains(permission) ?? false;
  }

  /// الحصول على جميع الصلاحيات
  List<UserPermission> getAllPermissions() {
    final allPermissions = <UserPermission>[];
    for (final sectionPermissions in permissions.values) {
      allPermissions.addAll(sectionPermissions);
    }
    return allPermissions.toSet().toList(); // Remove duplicates
  }

  /// التحقق من صحة البيانات
  bool get isValid {
    return name.isNotEmpty;
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, permissions: ${permissions.length} sections)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

/// تعيين الصلاحيات للأقسام المختلفة
class SectionPermissionMapper {
  /// الحصول على الصلاحيات المرتبطة بقسم معين
  static List<UserPermission> getPermissionsForSection(SystemSection section) {
    switch (section) {
      case SystemSection.finance:
        return [
          UserPermission.viewProfitCosts,
          UserPermission.exportReports,
        ];
      case SystemSection.hr:
        return [
          UserPermission.manageUsers,
        ];
      case SystemSection.sales:
        return [
          UserPermission.manageSales,
          UserPermission.applyDiscount,
          UserPermission.overridePrice,
          UserPermission.refundSales,
          UserPermission.voidSale,
          UserPermission.deleteSaleItem,
          UserPermission.openCashDrawer,
          UserPermission.manageCustomers,
        ];
      case SystemSection.inventory:
        return [
          UserPermission.manageProducts,
          UserPermission.manageInventory,
          UserPermission.adjustStock,
          UserPermission.viewCostPrice,
          UserPermission.editCostPrice,
          UserPermission.receivePurchase,
          UserPermission.manageSuppliers,
          UserPermission.manageCategories,
        ];
      case SystemSection.reports:
        return [
          UserPermission.viewReports,
          UserPermission.exportReports,
          UserPermission.viewProfitCosts,
        ];
      case SystemSection.system:
        return [
          UserPermission.systemSettings,
          UserPermission.manageBackup,
          UserPermission.manageLicensing,
        ];
    }
  }

  /// الحصول على القسم المرتبط بصلاحية معينة
  static SystemSection? getSectionForPermission(UserPermission permission) {
    for (final section in SystemSection.values) {
      if (getPermissionsForSection(section).contains(permission)) {
        return section;
      }
    }
    return null;
  }
}
