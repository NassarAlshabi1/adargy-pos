// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/db/database_service.dart';

/// خدمة التصدير والاستيراد لملفات Excel
class ExcelService {
  final DatabaseService _db;

  ExcelService(this._db);

  /// تصدير المنتجات إلى Excel
  Future<String?> exportProducts() async {
    try {
      // الحصول على المنتجات مع أسماء الفئات
      final products = await _db.database.rawQuery('''
        SELECT 
          p.*,
          c.name as category_name
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        ORDER BY p.id DESC
      ''');

      if (products.isEmpty) {
        throw Exception('لا توجد منتجات للتصدير');
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['المنتجات'];

      // رؤوس الأعمدة
      final headers = [
        'الرقم',
        'الاسم',
        'الفئة',
        'سعر الشراء',
        'سعر البيع',
        'الكمية',
        'الحد الأدنى',
        'الباركود',
        'تاريخ الإنشاء',
      ];

      // إضافة الرؤوس
      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // إضافة البيانات
      for (int row = 0; row < products.length; row++) {
        final product = products[row];
        final rowIndex = row + 1;

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(product['id'] as int);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(product['name']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(product['category_name']?.toString() ?? '');
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 3, rowIndex: rowIndex))
                .value =
            DoubleCellValue((product['cost'] as num?)?.toDouble() ?? 0.0);
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 4, rowIndex: rowIndex))
                .value =
            DoubleCellValue((product['price'] as num?)?.toDouble() ?? 0.0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = IntCellValue(product['quantity'] as int? ?? 0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = IntCellValue(product['min_quantity'] as int? ?? 0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = TextCellValue(product['barcode']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
            .value = TextCellValue(product['created_at']?.toString() ?? '');
      }

      // ضبط عرض الأعمدة
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15.0);
      }

      return await _saveExcelFile(
          excel, 'منتجات_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    } catch (e) {
      rethrow;
    }
  }

  /// تصدير العملاء إلى Excel
  Future<String?> exportCustomers() async {
    try {
      final customers = await _db.getCustomers();
      if (customers.isEmpty) {
        throw Exception('لا يوجد عملاء للتصدير');
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['العملاء'];

      final headers = [
        'الرقم',
        'الاسم',
        'الهاتف',
        'العنوان',
        'إجمالي الدين',
        'تاريخ الإنشاء'
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      for (int row = 0; row < customers.length; row++) {
        final customer = customers[row];
        final rowIndex = row + 1;

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(customer['id'] as int);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(customer['name']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(customer['phone']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(customer['address']?.toString() ?? '');
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 4, rowIndex: rowIndex))
                .value =
            DoubleCellValue(
                (customer['total_debt'] as num?)?.toDouble() ?? 0.0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(customer['created_at']?.toString() ?? '');
      }

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      return await _saveExcelFile(
          excel, 'عملاء_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    } catch (e) {
      rethrow;
    }
  }

  /// تصدير الموردين إلى Excel
  Future<String?> exportSuppliers() async {
    try {
      final suppliers = await _db.getSuppliers();
      if (suppliers.isEmpty) {
        throw Exception('لا يوجد موردون للتصدير');
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['الموردون'];

      final headers = [
        'الرقم',
        'الاسم',
        'الهاتف',
        'العنوان',
        'المستحقات',
        'تاريخ الإنشاء'
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      for (int row = 0; row < suppliers.length; row++) {
        final supplier = suppliers[row];
        final rowIndex = row + 1;

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(supplier['id'] as int);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(supplier['name']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(supplier['phone']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(supplier['address']?.toString() ?? '');
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 4, rowIndex: rowIndex))
                .value =
            DoubleCellValue(
                (supplier['total_payable'] as num?)?.toDouble() ?? 0.0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(supplier['created_at']?.toString() ?? '');
      }

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      return await _saveExcelFile(
          excel, 'موردون_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    } catch (e) {
      rethrow;
    }
  }

  /// تصدير المبيعات إلى Excel
  Future<String?> exportSales({DateTime? from, DateTime? to}) async {
    try {
      final sales = await _db.getSalesHistory(from: from, to: to);
      if (sales.isEmpty) {
        throw Exception('لا توجد مبيعات للتصدير');
      }

      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['المبيعات'];

      final headers = [
        'رقم الفاتورة',
        'العميل',
        'المجموع',
        'الربح',
        'نوع الدفع',
        'تاريخ البيع',
        'تاريخ الاستحقاق',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      for (int row = 0; row < sales.length; row++) {
        final sale = sales[row];
        final rowIndex = row + 1;

        String paymentType = 'نقدي';
        if (sale['type'] == 'credit') paymentType = 'آجل';
        if (sale['type'] == 'installment') paymentType = 'تقسيط';

        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = IntCellValue(sale['id'] as int);
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 1, rowIndex: rowIndex))
                .value =
            TextCellValue(sale['customer_name']?.toString() ?? 'عميل نقدي');
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 2, rowIndex: rowIndex))
                .value =
            DoubleCellValue((sale['total'] as num?)?.toDouble() ?? 0.0);
        sheet
                .cell(CellIndex.indexByColumnRow(
                    columnIndex: 3, rowIndex: rowIndex))
                .value =
            DoubleCellValue((sale['profit'] as num?)?.toDouble() ?? 0.0);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(paymentType);
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(sale['created_at']?.toString() ?? '');
        sheet
            .cell(
                CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(sale['due_date']?.toString() ?? '');
      }

      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      final fileName = from != null && to != null
          ? 'مبيعات_${from.year}_${from.month}_${from.day}_إلى_${to.year}_${to.month}_${to.day}.xlsx'
          : 'مبيعات_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      return await _saveExcelFile(excel, fileName);
    } catch (e) {
      rethrow;
    }
  }

  /// حفظ ملف Excel
  Future<String?> _saveExcelFile(Excel excel, String fileName) async {
    try {
      // إنشاء ملف Excel أولاً
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('فشل في إنشاء ملف Excel');
      }

      // استخدام FilePicker دائماً لإظهار نافذة الحفظ
      String? path;
      try {
        path = await FilePicker.platform.saveFile(
          dialogTitle: 'اختر مكان حفظ ملف Excel',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            return null;
          },
        );
      } catch (e) {
        // في حالة فشل FilePicker، حفظ الملف في مجلد Downloads كبديل
        try {
          final downloadsDir = await _getDownloadsDirectory();
          if (downloadsDir != null) {
            // التأكد من عدم وجود ملف بنفس الاسم
            var finalPath = Platform.isWindows
                ? '${downloadsDir.path}\\$fileName'
                : '${downloadsDir.path}/$fileName';
            var counter = 1;
            while (await File(finalPath).exists()) {
              final nameWithoutExt =
                  fileName.replaceAll(RegExp(r'\.xlsx$'), '');
              finalPath = Platform.isWindows
                  ? '${downloadsDir.path}\\${nameWithoutExt}_$counter.xlsx'
                  : '${downloadsDir.path}/${nameWithoutExt}_$counter.xlsx';
              counter++;
            }
            path = finalPath;
          } else {
            throw Exception('لا يمكن الوصول إلى مجلد التنزيلات');
          }
        } catch (e2) {
          rethrow;
        }
      }

      if (path == null) {
        return null;
      }

      // كتابة الملف
      final file = File(path);
      await file.writeAsBytes(fileBytes, flush: true);

      return path;
    } catch (e) {
      rethrow;
    }
  }

  /// الحصول على مجلد التنزيلات
  Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final downloadsPath = '$userProfile\\Downloads';
          final dir = Directory(downloadsPath);
          if (await dir.exists()) {
            return dir;
          }
        }
      } else if (Platform.isLinux) {
        final userHome = Platform.environment['HOME'];
        if (userHome != null) {
          final downloadsPath = '$userHome/Downloads';
          final dir = Directory(downloadsPath);
          if (await dir.exists()) {
            return dir;
          }
        }
      } else if (Platform.isMacOS) {
        final userHome = Platform.environment['HOME'];
        if (userHome != null) {
          final downloadsPath = '$userHome/Downloads';
          final dir = Directory(downloadsPath);
          if (await dir.exists()) {
            return dir;
          }
        }
      }

      // استخدام path_provider كبديل
      try {
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          final directory = await getApplicationDocumentsDirectory();
          return directory;
        }
        return null;
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// استيراد المنتجات من Excel
  Future<Map<String, dynamic>> importProducts() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        dialogTitle: 'اختر ملف Excel للمنتجات',
      );

      if (result == null || result.files.single.path == null) {
        return {'success': false, 'message': 'لم يتم اختيار ملف'};
      }

      final filePath = result.files.single.path!;

      final bytes = File(filePath).readAsBytesSync();

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return {'success': false, 'message': 'الملف فارغ أو غير صالح'};
      }

      // البحث عن الورقة الصحيحة - محاولة العثور على "المنتجات" أولاً
      Sheet? sheet;

      if (excel.tables.containsKey('المنتجات')) {
        sheet = excel.tables['المنتجات'];
      } else {
        // استخدام أول ورقة متاحة
        sheet = excel.tables.values.first;
      }

      if (sheet == null) {
        return {
          'success': false,
          'message': 'لا يمكن العثور على ورقة في الملف'
        };
      }

      // التحقق من وجود بيانات فعلية
      int dataRowCount = 0;
      for (int row = 0; row < sheet.maxRows; row++) {
        bool hasData = false;
        // التحقق من أول 10 أعمدة
        for (int col = 0; col < 10; col++) {
          try {
            final cell = sheet.cell(
                CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null) {
              final value = cell.value.toString().trim();
              if (value.isNotEmpty) {
                hasData = true;
                break;
              }
            }
          } catch (e) {
            // تجاهل الأخطاء في قراءة الخلايا
          }
        }
        if (hasData) dataRowCount++;
      }

      if (dataRowCount < 2) {
        return {
          'success': false,
          'message':
              'لا توجد بيانات في الملف (يجب أن يحتوي على رؤوس وصف واحد على الأقل)'
        };
      }

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      final errors = <String>[];

      // تخطي الصف الأول (الرؤوس)
      // استخدام maxRows أو البحث عن آخر صف يحتوي على بيانات
      int maxDataRow = sheet.maxRows;

      // إذا كان maxRows = 0، نحاول البحث عن آخر صف يحتوي على بيانات
      if (maxDataRow == 0) {
        // maxRows = 0، البحث عن البيانات...');
        for (int row = 0; row < 1000; row++) {
          bool hasData = false;
          for (int col = 0; col < 10; col++) {
            try {
              final cell = sheet.cell(
                  CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
              if (cell.value != null &&
                  cell.value.toString().trim().isNotEmpty) {
                hasData = true;
                maxDataRow = row + 1;
                break;
              }
            } catch (e) {
              // تجاهل الأخطاء
            }
          }
          if (!hasData && maxDataRow > 0) {
            // إذا لم نجد بيانات بعد أن وجدنا صفوف سابقة، نتوقف
            break;
          }
        }
      }

      if (maxDataRow < 2) {
        return {
          'success': false,
          'message':
              'لا توجد بيانات في الملف (يجب أن يحتوي على رؤوس وصف واحد على الأقل)'
        };
      }

      for (int row = 1; row < maxDataRow; row++) {
        try {
          // قراءة البيانات من الأعمدة
          // العمود 0: الرقم (نحذفه)
          // العمود 1: الاسم
          // العمود 2: الفئة
          // العمود 3: سعر الشراء
          // العمود 4: سعر البيع
          // العمود 5: الكمية
          // العمود 6: الحد الأدنى
          // العمود 7: الباركود
          // العمود 8: تاريخ الإنشاء (نحذفه)

          final nameCell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
          final name = (nameCell.value?.toString() ?? '').trim();

          if (name.isEmpty) {
            skippedCount++;
            continue;
          }

          final categoryName = (sheet
                      .cell(CellIndex.indexByColumnRow(
                          columnIndex: 2, rowIndex: row))
                      .value
                      ?.toString() ??
                  '')
              .trim();

          // قراءة القيم الرقمية مع سجلات تفصيلية
          final costCell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
          final cost = _parseDouble(costCell.value);

          final priceCell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
          final price = _parseDouble(priceCell.value);

          final quantityCell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));
          final quantity = _parseInt(quantityCell.value);

          final minQuantityCell = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));
          final minQuantity = _parseInt(minQuantityCell.value);

          final barcode = (sheet
                      .cell(CellIndex.indexByColumnRow(
                          columnIndex: 7, rowIndex: row))
                      .value
                      ?.toString() ??
                  '')
              .trim();

          // التحقق من البيانات الأساسية
          if (price < 0) {
            throw Exception('سعر البيع يجب أن يكون أكبر من أو يساوي صفر');
          }

          // البحث عن الفئة أو إنشاؤها
          int? categoryId;
          if (categoryName.isNotEmpty) {
            try {
              final categories = await _db.getCategories();
              var category = categories.firstWhere(
                (c) =>
                    c['name']?.toString().trim().toLowerCase() ==
                    categoryName.trim().toLowerCase(),
                orElse: () => {},
              );

              if (category.isEmpty) {
                categoryId = await _db.upsertCategory({'name': categoryName});
                // تم إنشاء فئة جديدة
              } else {
                categoryId = category['id'] as int?;
              }
            } catch (e) {
              // نستمر بدون فئة
            }
          }

          // محاولة إدراج المنتج
          try {
            await _db.insertProduct({
              'name': name,
              'cost': cost >= 0 ? cost : 0.0,
              'price': price,
              'quantity': quantity >= 0 ? quantity : 0,
              'min_quantity': minQuantity >= 0 ? minQuantity : 0,
              'barcode': barcode,
              // ملاحظة: description غير موجود في جدول products
              'category_id': categoryId,
            });

            successCount++;
          } catch (e) {
            // إذا كان الخطأ بسبب الباركود الموجود، نحاول التحديث بدلاً من الإضافة
            if (e.toString().contains('الباركود موجود') ||
                e.toString().contains('barcode') ||
                e.toString().contains('موجود')) {
              // نحاول العثور على المنتج بالباركود أولاً، ثم بالاسم
              try {
                final products = await _db.getAllProducts();
                Map<String, Object?>? existingProduct;

                // البحث بالباركود أولاً (إذا كان موجود)
                if (barcode.isNotEmpty) {
                  try {
                    existingProduct = products.firstWhere(
                      (p) {
                        final pBarcode = p['barcode']?.toString().trim() ?? '';
                        return pBarcode.isNotEmpty &&
                            pBarcode == barcode.trim();
                      },
                      orElse: () => <String, Object?>{},
                    );
                    if (existingProduct.isNotEmpty) {}
                  } catch (e) {
                    // تجاهل خطأ البحث عن المنتج بالباركود والاستمرار بالبحث بالاسم
                  }
                }

                // إذا لم نجد بالباركود، نبحث بالاسم
                if (existingProduct == null || existingProduct.isEmpty) {
                  try {
                    existingProduct = products.firstWhere(
                      (p) {
                        final pName =
                            p['name']?.toString().trim().toLowerCase() ?? '';
                        return pName == name.trim().toLowerCase();
                      },
                      orElse: () => <String, Object?>{},
                    );
                    if (existingProduct.isNotEmpty) {}
                  } catch (e) {
                    // تجاهل خطأ البحث عن المنتج بالاسم والاستمرار
                  }
                }

                if (existingProduct != null && existingProduct.isNotEmpty) {
                  final productId = existingProduct['id'] as int;

                  await _db.updateProduct(productId, {
                    'name': name,
                    'cost': cost >= 0 ? cost : 0.0,
                    'price': price,
                    'quantity': quantity >= 0 ? quantity : 0,
                    'min_quantity': minQuantity >= 0 ? minQuantity : 0,
                    'barcode': barcode,
                    // ملاحظة: description غير موجود في جدول products
                    'category_id': categoryId,
                  });
                  successCount++;
                } else {
                  // إذا لم نجد المنتج، نحاول إضافة منتج جديد بدون باركود
                  try {
                    await _db.insertProduct({
                      'name': name,
                      'cost': cost >= 0 ? cost : 0.0,
                      'price': price,
                      'quantity': quantity >= 0 ? quantity : 0,
                      'min_quantity': minQuantity >= 0 ? minQuantity : 0,
                      'barcode': '', // إضافة بدون باركود لتجنب التكرار
                      // ملاحظة: description غير موجود في جدول products
                      'category_id': categoryId,
                    });
                    successCount++;
                  } catch (e3) {
                    errorCount++;
                    errors.add(
                        'صف ${row + 1} ($name): فشل في إضافة/تحديث المنتج - $e3');
                  }
                }
              } catch (e2) {
                errorCount++;
                errors.add('صف ${row + 1} ($name): $e2');
              }
            } else {
              rethrow;
            }
          }
        } catch (e) {
          errorCount++;
          final errorMsg = 'صف ${row + 1}: $e';
          errors.add(errorMsg);
        }
      }

      String message = 'تم استيراد $successCount منتج بنجاح';
      if (skippedCount > 0) {
        message += '\nتم تخطي $skippedCount صف (اسم فارغ)';
      }
      if (errorCount > 0) {
        message += '\nفشل استيراد $errorCount منتج';
      }

      return {
        'success': successCount > 0,
        'message': message,
        'successCount': successCount,
        'errorCount': errorCount,
        'skippedCount': skippedCount,
        'errors': errors,
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في استيراد المنتجات: $e'};
    }
  }

  /// استيراد العملاء من Excel
  Future<Map<String, dynamic>> importCustomers() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        dialogTitle: 'اختر ملف Excel للعملاء',
      );

      if (result == null || result.files.single.path == null) {
        return {'success': false, 'message': 'لم يتم اختيار ملف'};
      }

      final filePath = result.files.single.path!;
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return {'success': false, 'message': 'الملف فارغ أو غير صالح'};
      }

      final sheet = excel.tables.values.first;
      if (sheet.maxRows < 2) {
        return {'success': false, 'message': 'لا توجد بيانات في الملف'};
      }

      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      for (int row = 1; row < sheet.maxRows; row++) {
        try {
          final name = sheet
                  .cell(
                      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
                  .value
                  ?.toString() ??
              '';
          if (name.isEmpty) continue;

          final phone = sheet
                  .cell(
                      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
                  .value
                  ?.toString() ??
              '';
          final address = sheet
                  .cell(
                      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
                  .value
                  ?.toString() ??
              '';

          await _db.upsertCustomer({
            'name': name,
            'phone': phone,
            'address': address,
          });

          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('صف ${row + 1}: $e');
        }
      }

      return {
        'success': true,
        'message': 'تم استيراد $successCount عميل بنجاح',
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في استيراد العملاء: $e'};
    }
  }

  /// مساعدات لتحويل القيم
  double _parseDouble(dynamic value) {
    if (value == null) {
      // _parseDouble: قيمة null');
      return 0.0;
    }

    // إذا كانت القيمة من نوع CellValue
    if (value is DoubleCellValue) {
      final result = value.value;
      return result;
    }
    if (value is IntCellValue) {
      final result = value.value.toDouble();
      return result;
    }
    if (value is TextCellValue) {
      // TextCellValue يحتوي على TextSpan، نحتاج لتحويله إلى String
      try {
        final textSpan = value.value;
        String str;
        // محاولة استخراج النص من TextSpan
        try {
          // TextSpan يحتوي على خاصية text
          str = (textSpan as dynamic).text?.toString() ?? textSpan.toString();
        } catch (_) {
          // إذا فشل، استخدم toString()
          str = textSpan.toString();
        }
        str = str.replaceAll(',', '').replaceAll(RegExp(r'\s+'), '').trim();
        final parsed = double.tryParse(str);
        return parsed ?? 0.0;
      } catch (e) {
        // محاولة استخدام toString() مباشرة
        try {
          final str = value
              .toString()
              .replaceAll(',', '')
              .replaceAll(RegExp(r'\s+'), '')
              .trim();
          final parsed = double.tryParse(str);
          return parsed ?? 0.0;
        } catch (_) {
          return 0.0;
        }
      }
    }

    // إذا كانت القيمة رقمية مباشرة
    if (value is num) {
      return value.toDouble();
    }

    // إذا كانت القيمة نصية
    if (value is String) {
      final str = value.replaceAll(',', '').replaceAll(' ', '').trim();
      final parsed = double.tryParse(str);
      return parsed ?? 0.0;
    }

    // محاولة التحويل إلى String ثم التحليل
    try {
      final str =
          value.toString().replaceAll(',', '').replaceAll(' ', '').trim();
      final parsed = double.tryParse(str);
      return parsed ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) {
      // _parseInt: قيمة null');
      return 0;
    }

    // إذا كانت القيمة من نوع CellValue
    if (value is IntCellValue) {
      final result = value.value;
      return result;
    }
    if (value is DoubleCellValue) {
      final result = value.value.toInt();
      return result;
    }
    if (value is TextCellValue) {
      // TextCellValue يحتوي على TextSpan، نحتاج لتحويله إلى String
      try {
        final textSpan = value.value;
        String str;
        // محاولة استخراج النص من TextSpan
        try {
          // TextSpan يحتوي على خاصية text
          str = (textSpan as dynamic).text?.toString() ?? textSpan.toString();
        } catch (_) {
          // إذا فشل، استخدم toString()
          str = textSpan.toString();
        }
        str = str.replaceAll(',', '').replaceAll(RegExp(r'\s+'), '').trim();
        // محاولة التحويل إلى double أولاً ثم int (للتأكد من معالجة الأرقام العشرية)
        final doubleParsed = double.tryParse(str);
        if (doubleParsed != null) {
          final result = doubleParsed.toInt();
          return result;
        }
        final parsed = int.tryParse(str);
        return parsed ?? 0;
      } catch (e) {
        // محاولة استخدام toString() مباشرة
        try {
          final str = value
              .toString()
              .replaceAll(',', '')
              .replaceAll(RegExp(r'\s+'), '')
              .trim();
          final doubleParsed = double.tryParse(str);
          if (doubleParsed != null) {
            return doubleParsed.toInt();
          }
          final parsed = int.tryParse(str);
          return parsed ?? 0;
        } catch (_) {
          return 0;
        }
      }
    }

    // إذا كانت القيمة رقمية مباشرة
    if (value is num) {
      return value.toInt();
    }

    // إذا كانت القيمة نصية
    if (value is String) {
      final str = value.replaceAll(',', '').replaceAll(' ', '').trim();
      // محاولة التحويل إلى double أولاً ثم int
      final doubleParsed = double.tryParse(str);
      if (doubleParsed != null) {
        final result = doubleParsed.toInt();
        return result;
      }
      final parsed = int.tryParse(str);
      return parsed ?? 0;
    }

    // محاولة التحويل إلى String ثم التحليل
    try {
      final str =
          value.toString().replaceAll(',', '').replaceAll(' ', '').trim();
      final doubleParsed = double.tryParse(str);
      if (doubleParsed != null) {
        final result = doubleParsed.toInt();
        return result;
      }
      final parsed = int.tryParse(str);
      return parsed ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
