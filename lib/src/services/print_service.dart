// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/invoice_pdf.dart';
import '../utils/dark_mode_utils.dart';
import 'store_info_service.dart';

class PrintService {
  static const String _defaultPageFormat = 'A4';
  static const bool _defaultShowLogo = true;
  static const bool _defaultShowBarcode = true;

  // إعدادات الطباعة المحفوظة
  static String _savedPageFormat = _defaultPageFormat;
  static bool _savedShowLogo = _defaultShowLogo;
  static bool _savedShowBarcode = _defaultShowBarcode;

  // طباعة كشف حساب العميل
  static Future<bool> printCustomerStatement({
    required String shopName,
    required String? phone,
    required String? address,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> payments,
    required Map<String, dynamic> debtData,
    String? pageFormat,
    BuildContext? context,
  }) async {
    try {
      // إنشاء PDF لكشف الحساب
      final pdfBytes = await _generateStatementPDF(
        shopName: shopName,
        phone: phone,
        address: address,
        customer: customer,
        payments: payments,
        debtData: debtData,
        pageFormat: pageFormat ?? _savedPageFormat,
      );

      // طباعة PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
            'كشف_حساب_${customer['name']}_${DateTime.now().millisecondsSinceEpoch}',
      );

      return true;
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طباعة كشف الحساب: $e'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
      }
      return false;
    }
  }

  // إنشاء PDF لكشف الحساب
  static Future<Uint8List> _generateStatementPDF({
    required String shopName,
    required String? phone,
    required String? address,
    required Map<String, dynamic> customer,
    required List<Map<String, dynamic>> payments,
    required Map<String, dynamic> debtData,
    required String pageFormat,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // تحميل الخط العربي
    final arabicFont = await _loadArabicFont();

    // تحديد نوع الورق
    final format = _getPageFormat(pageFormat);

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس كشف الحساب
                _buildStatementHeader(
                    shopName, phone, address, customer, date, arabicFont),
                pw.SizedBox(height: 20),

                // ملخص الحساب
                _buildAccountSummary(debtData, arabicFont),
                pw.SizedBox(height: 20),

                // تفاصيل المدفوعات
                _buildPaymentsTable(payments, arabicFont),
                pw.SizedBox(height: 20),

                // تذييل
                _buildStatementFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // بناء رأس كشف الحساب
  static pw.Widget _buildStatementHeader(
    String shopName,
    String? phone,
    String? address,
    Map<String, dynamic> customer,
    String date,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'كشف حساب العميل',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            shopName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (phone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'الهاتف: $phone',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          if (address != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'العنوان: $address',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'العميل: ${customer['name']}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (customer['phone'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'هاتف العميل: ${customer['phone']}',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'تاريخ الكشف: $date',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء ملخص الحساب
  static pw.Widget _buildAccountSummary(
    Map<String, dynamic> debtData,
    pw.Font arabicFont,
  ) {
    final totalDebt = debtData['totalDebt'] ?? 0.0;
    final totalPaid = debtData['totalPaid'] ?? 0.0;
    final remainingDebt = debtData['remainingDebt'] ?? 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ملخص الحساب',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الدين:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${totalDebt.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي المدفوع:',
                style: pw.TextStyle(fontSize: 10, font: arabicFont),
              ),
              pw.Text(
                '${totalPaid.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المتبقي:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  font: arabicFont,
                ),
              ),
              pw.Text(
                '${remainingDebt.toStringAsFixed(0)} د.ع',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: remainingDebt > 0 ? PdfColors.red : PdfColors.green,
                  font: arabicFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء جدول المدفوعات
  static pw.Widget _buildPaymentsTable(
    List<Map<String, dynamic>> payments,
    pw.Font arabicFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'تفاصيل المدفوعات',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
        ),
        pw.SizedBox(height: 8),
        if (payments.isEmpty)
          pw.Text(
            'لا توجد مدفوعات',
            style: pw.TextStyle(fontSize: 10, font: arabicFont),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(width: 1),
            columnWidths: {
              0: const pw.FixedColumnWidth(80),
              1: const pw.FixedColumnWidth(100),
              2: const pw.FixedColumnWidth(60),
            },
            children: [
              // رأس الجدول
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'التاريخ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'المبلغ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'الطريقة',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              // صفوف المدفوعات
              ...payments.map((payment) {
                final date = DateTime.parse(payment['payment_date']);
                final amount = payment['amount'] ?? 0.0;
                final method = payment['payment_method'] ?? 'نقد';

                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${amount.toStringAsFixed(0)} د.ع',
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        method,
                        style: pw.TextStyle(fontSize: 9, font: arabicFont),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  // بناء تذييل كشف الحساب
  static pw.Widget _buildStatementFooter(pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'شكراً لاختياركم خدماتنا',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'هذا الكشف صادر من تجارتي',
          style: pw.TextStyle(fontSize: 8, font: arabicFont),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // تحميل الخط العربي
  static Future<pw.Font> _loadArabicFont() async {
    try {
      final fontData = await rootBundle
          .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      return pw.Font.helvetica();
    }
  }

  // الحصول على نوع الورق
  static PdfPageFormat _getPageFormat(String formatName) {
    switch (formatName) {
      case '58':
        return const PdfPageFormat(
            58 * PdfPageFormat.mm, 250 * PdfPageFormat.mm);
      case '80':
        return const PdfPageFormat(
            80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm);
      case 'A4':
        return PdfPageFormat.a4;
      case 'A5':
        return PdfPageFormat.a5;
      default:
        return PdfPageFormat.a4;
    }
  }

  // طباعة فاتورة مع خيارات متقدمة
  static Future<bool> printInvoice({
    required String shopName,
    required String? phone,
    required String? address,
    required List<Map<String, Object?>> items,
    required String paymentType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? dueDate,
    String? pageFormat,
    bool? showLogo,
    bool? showBarcode,
    String? invoiceNumber, // رقم الفاتورة من قاعدة البيانات
    List<Map<String, Object?>>? installments, // معلومات الأقساط
    double? totalDebt, // إجمالي الدين
    double? downPayment, // المبلغ المقدم
    double? couponDiscount, // خصم الكوبون
    double? subtotal, // الإجمالي قبل الكوبون
    BuildContext? context,
  }) async {
    try {
      // إضافة رسائل تشخيص

      // فحص أن هناك منتجات للطباعة
      if (items.isEmpty) {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا توجد منتجات للطباعة'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      // الحصول على معلومات المتجر المبسطة
      final storeInfo = await StoreInfoService.getPrintInfo();

      final pdfData = await InvoicePdf.generate(
        shopName: storeInfo['store_name'] ?? shopName,
        phone: storeInfo['phone'] ?? phone,
        address: storeInfo['address'] ?? address,
        description: storeInfo['description'], // وصف المحل
        items: items,
        paymentType: paymentType,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        dueDate: dueDate,
        pageFormat: pageFormat ?? _savedPageFormat,
        showLogo: showLogo ?? _savedShowLogo,
        showBarcode: showBarcode ?? _savedShowBarcode,
        invoiceNumber: invoiceNumber,
        installments: installments,
        totalDebt: totalDebt,
        downPayment: downPayment,
        couponDiscount: couponDiscount,
        subtotal: subtotal,
      );

      try {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          name: 'فاتورة_${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (layoutError) {
        // محاولة بديلة - حفظ الملف وعرضه
        try {
          await Printing.sharePdf(
            bytes: pdfData,
            filename: 'فاتورة_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
        } catch (shareError) {
          rethrow;
        }
      }

      return true;
    } catch (e) {
      if (context != null) {
        String errorMessage = 'خطأ في الطباعة';

        // تحسين رسائل الخطأ
        if (e.toString().contains('No such file or directory')) {
          errorMessage = 'خطأ: ملف الخط العربي غير موجود';
        } else if (e.toString().contains('Permission denied')) {
          errorMessage = 'خطأ: لا توجد صلاحية للطباعة';
        } else if (e.toString().contains('Device not found')) {
          errorMessage = 'خطأ: الطابعة غير متصلة';
        } else if (e.toString().contains('Out of paper')) {
          errorMessage = 'خطأ: نفدت الورق من الطابعة';
        } else {
          errorMessage = 'خطأ في الطباعة: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: DarkModeUtils.getErrorColor(context),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  // عرض خيارات الطباعة
  static Future<Map<String, dynamic>?> showPrintOptionsDialog(
      BuildContext context) {
    String selectedFormat = _savedPageFormat;
    bool showLogo = _savedShowLogo;
    bool showBarcode = _savedShowBarcode;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.print, color: DarkModeUtils.getInfoColor(context)),
              const SizedBox(width: 8),
              const Text('خيارات الطباعة'),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
              minWidth: 600,
              maxHeight: 750,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اختيار نوع الورق
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DarkModeUtils.getBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: DarkModeUtils.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الورق والطابعة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedFormat,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: DarkModeUtils.getBorderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: DarkModeUtils.getBorderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: DarkModeUtils.getInfoColor(context),
                                width: 2),
                          ),
                          filled: true,
                          fillColor: DarkModeUtils.getCardColor(context),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          prefixIcon: Icon(
                            Icons.print,
                            color: DarkModeUtils.getInfoColor(context),
                            size: 20,
                          ),
                          hintText: 'اختر نوع الورق',
                          hintStyle: TextStyle(
                            color: DarkModeUtils.getSecondaryTextColor(context),
                            fontSize: 11,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: DarkModeUtils.getTextColor(context),
                        ),
                        dropdownColor: DarkModeUtils.getCardColor(context),
                        selectedItemBuilder: (BuildContext context) {
                          return InvoicePdf.getAvailablePageFormats()
                              .map<Widget>((String format) {
                            final info = InvoicePdf.getPageFormatInfo(format);
                            return Container(
                              alignment: Alignment.centerRight,
                              child: Text(
                                info['description'] ?? format,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DarkModeUtils.getTextColor(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();
                        },
                        items:
                            InvoicePdf.getAvailablePageFormats().map((format) {
                          final info = InvoicePdf.getPageFormatInfo(format);
                          return DropdownMenuItem<String>(
                            value: format,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 8),
                              constraints: const BoxConstraints(
                                  minHeight: 65, maxHeight: 75),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color:
                                          DarkModeUtils.getInfoColor(context),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          info['description'] ?? format,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: DarkModeUtils.getTextColor(
                                                context),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${info['width']?.toStringAsFixed(0)} × ${info['height']?.toStringAsFixed(0)} مم',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: DarkModeUtils
                                                .getSecondaryTextColor(context),
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: selectedFormat == format
                                        ? DarkModeUtils.getSuccessColor(context)
                                        : Colors.transparent,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedFormat = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // خيارات إضافية
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DarkModeUtils.getBackgroundColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: DarkModeUtils.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'خيارات إضافية:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('عرض الشعار'),
                        subtitle: const Text('إضافة شعار المحل للفاتورة'),
                        value: showLogo,
                        onChanged: (value) {
                          setState(() {
                            showLogo = value ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('عرض الباركود'),
                        subtitle: const Text('إضافة باركود للفاتورة'),
                        value: showBarcode,
                        onChanged: (value) {
                          setState(() {
                            showBarcode = value ?? true;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // معاينة سريعة
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DarkModeUtils.getInfoColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: DarkModeUtils.getInfoColor(context)
                            .withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: DarkModeUtils.getInfoColor(context), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم حفظ هذه الإعدادات للاستخدام في المستقبل',
                          style: TextStyle(
                            fontSize: 12,
                            color: DarkModeUtils.getInfoColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // حفظ الإعدادات
                _savedPageFormat = selectedFormat;
                _savedShowLogo = showLogo;
                _savedShowBarcode = showBarcode;

                Navigator.of(context).pop({
                  'pageFormat': selectedFormat,
                  'showLogo': showLogo,
                  'showBarcode': showBarcode,
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('موافق'),
            ),
          ],
        ),
      ),
    );
  }

  // الحصول على الإعدادات المحفوظة
  static Map<String, dynamic> getSavedSettings() {
    return {
      'pageFormat': _savedPageFormat,
      'showLogo': _savedShowLogo,
      'showBarcode': _savedShowBarcode,
    };
  }

  // حفظ الإعدادات
  static void saveSettings({
    String? pageFormat,
    bool? showLogo,
    bool? showBarcode,
  }) {
    if (pageFormat != null) _savedPageFormat = pageFormat;
    if (showLogo != null) _savedShowLogo = showLogo;
    if (showBarcode != null) _savedShowBarcode = showBarcode;
  }

  // إعادة تعيين الإعدادات للافتراضية
  static void resetToDefaults() {
    _savedPageFormat = _defaultPageFormat;
    _savedShowLogo = _defaultShowLogo;
    _savedShowBarcode = _defaultShowBarcode;
  }

  // طباعة سريعة بالإعدادات المحفوظة
  static Future<bool> quickPrint({
    required String shopName,
    required String? phone,
    required String? address,
    required List<Map<String, Object?>> items,
    required String paymentType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? dueDate,
    String? invoiceNumber, // رقم الفاتورة من قاعدة البيانات
    BuildContext? context,
  }) async {
    // فحص أن هناك منتجات للطباعة
    if (items.isEmpty) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد منتجات للطباعة'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    return await printInvoice(
      shopName: shopName,
      phone: phone,
      address: address,
      items: items,
      paymentType: paymentType,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      dueDate: dueDate,
      pageFormat: _savedPageFormat,
      showLogo: _savedShowLogo,
      showBarcode: _savedShowBarcode,
      invoiceNumber: invoiceNumber,
      context: context,
    );
  }

  // طباعة التقارير المالية
  static Future<bool> printFinancialReport({
    required String reportType,
    required String title,
    required List<MapEntry<String, String>> items,
    required DateTime reportDate,
    String? shopName,
    String? phone,
    String? address,
    BuildContext? context,
  }) async {
    try {
      final pdfBytes = await _generateFinancialReportPDF(
        reportType: reportType,
        title: title,
        items: items,
        reportDate: reportDate,
        shopName: shopName,
        phone: phone,
        address: address,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${reportType}_${DateTime.now().millisecondsSinceEpoch}',
      );

      return true;
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طباعة التقرير: $e'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
      }
      return false;
    }
  }

  // طباعة تقارير الجرد
  static Future<bool> printInventoryReport({
    required String reportType,
    required String title,
    required List<MapEntry<String, String>> items,
    required DateTime reportDate,
    String? shopName,
    String? phone,
    String? address,
    BuildContext? context,
  }) async {
    try {
      final pdfBytes = await _generateInventoryReportPDF(
        reportType: reportType,
        title: title,
        items: items,
        reportDate: reportDate,
        shopName: shopName,
        phone: phone,
        address: address,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${reportType}_${DateTime.now().millisecondsSinceEpoch}',
      );

      return true;
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طباعة التقرير: $e'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
      }
      return false;
    }
  }

  // طباعة تقارير الجدول (مثل الأكثر مبيعاً)
  static Future<bool> printTableReport({
    required String reportType,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required DateTime reportDate,
    String? shopName,
    String? phone,
    String? address,
    BuildContext? context,
  }) async {
    try {
      final pdfBytes = await _generateTableReportPDF(
        reportType: reportType,
        title: title,
        headers: headers,
        rows: rows,
        reportDate: reportDate,
        shopName: shopName,
        phone: phone,
        address: address,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${reportType}_${DateTime.now().millisecondsSinceEpoch}',
      );

      return true;
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في طباعة التقرير: $e'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
      }
      return false;
    }
  }

  // إنشاء PDF للتقارير المالية
  static Future<Uint8List> _generateFinancialReportPDF({
    required String reportType,
    required String title,
    required List<MapEntry<String, String>> items,
    required DateTime reportDate,
    String? shopName,
    String? phone,
    String? address,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('d - M - yyyy').format(reportDate);
    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس التقرير
                _buildReportHeader(
                    title, date, shopName, phone, address, arabicFont),
                pw.SizedBox(height: 20),

                // محتوى التقرير
                _buildFinancialReportContent(items, arabicFont),
                pw.SizedBox(height: 20),

                // تذييل التقرير
                _buildReportFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // إنشاء PDF لتقارير الجرد
  static Future<Uint8List> _generateInventoryReportPDF({
    required String reportType,
    required String title,
    required List<MapEntry<String, String>> items,
    required DateTime reportDate,
    String? shopName,
    String? phone,
    String? address,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('d - M - yyyy').format(reportDate);
    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس التقرير
                _buildReportHeader(
                    title, date, shopName, phone, address, arabicFont),
                pw.SizedBox(height: 20),

                // محتوى التقرير
                _buildInventoryReportContent(items, arabicFont),
                pw.SizedBox(height: 20),

                // تذييل التقرير
                _buildReportFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // إنشاء PDF لتقارير الجدول
  static Future<Uint8List> _generateTableReportPDF({
    required String reportType,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required DateTime reportDate,
    String? shopName,
    String? phone,
    String? address,
  }) async {
    final doc = pw.Document();
    final date = DateFormat('d - M - yyyy').format(reportDate);
    final arabicFont = await _loadArabicFont();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // رأس التقرير
                _buildReportHeader(
                    title, date, shopName, phone, address, arabicFont),
                pw.SizedBox(height: 20),

                // محتوى التقرير
                _buildTableReportContent(headers, rows, arabicFont),
                pw.SizedBox(height: 20),

                // تذييل التقرير
                _buildReportFooter(arabicFont),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // بناء رأس التقرير
  static pw.Widget _buildReportHeader(
    String title,
    String date,
    String? shopName,
    String? phone,
    String? address,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
          if (shopName != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              shopName,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                font: arabicFont,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
          if (phone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'الهاتف: $phone',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          if (address != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'العنوان: $address',
              style: pw.TextStyle(fontSize: 10, font: arabicFont),
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'تاريخ التقرير: $date',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              font: arabicFont,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // بناء محتوى التقرير المالي
  static pw.Widget _buildFinancialReportContent(
    List<MapEntry<String, String>> items,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          // رأس الجدول
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'البند',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'القيمة',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
          // صفوف البيانات
          ...items.map((item) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      item.key,
                      style: pw.TextStyle(fontSize: 10, font: arabicFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      item.value,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  // بناء محتوى تقرير الجرد
  static pw.Widget _buildInventoryReportContent(
    List<MapEntry<String, String>> items,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
        },
        children: [
          // رأس الجدول
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'المؤشر',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'القيمة',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
          // صفوف البيانات
          ...items.map((item) => pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      item.key,
                      style: pw.TextStyle(fontSize: 10, font: arabicFont),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      item.value,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  // بناء محتوى تقرير الجدول
  static pw.Widget _buildTableReportContent(
    List<String> headers,
    List<List<String>> rows,
    pw.Font arabicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
        children: [
          // رأس الجدول
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: headers.reversed
                .map((header) => pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        header,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          font: arabicFont,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ))
                .toList(),
          ),
          // صفوف البيانات
          ...rows.map((row) => pw.TableRow(
                children: row.reversed
                    .map((cell) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            cell,
                            style: pw.TextStyle(fontSize: 9, font: arabicFont),
                            textAlign: pw.TextAlign.center,
                          ),
                        ))
                    .toList(),
              )),
        ],
      ),
    );
  }

  // بناء تذييل التقرير
  static pw.Widget _buildReportFooter(pw.Font arabicFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'تم إنشاء هذا التقرير بواسطة تجارتي',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            font: arabicFont,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'تاريخ الطباعة: ${DateFormat('d - M - yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontSize: 8, font: arabicFont),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
