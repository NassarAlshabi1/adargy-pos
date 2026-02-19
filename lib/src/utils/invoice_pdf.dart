import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'strings.dart';
import 'format.dart';

class InvoicePdf {
  // دعم أنواع مختلفة من الطابعات والأوراق
  static final Map<String, PdfPageFormat> _pageFormats = {
    '58': const PdfPageFormat(
        58 * PdfPageFormat.mm, 250 * PdfPageFormat.mm), // طابعة حرارية 58mm
    '80': const PdfPageFormat(
        80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm), // طابعة حرارية 80mm
    'A4': PdfPageFormat.a4, // ورقة A4
    'A5': PdfPageFormat.a5, // ورقة A5
    // Legacy support
    'thermal_58':
        const PdfPageFormat(58 * PdfPageFormat.mm, 250 * PdfPageFormat.mm),
    'thermal_80':
        const PdfPageFormat(80 * PdfPageFormat.mm, 300 * PdfPageFormat.mm),
    'a4': PdfPageFormat.a4,
    'a5': PdfPageFormat.a5,
    'letter': PdfPageFormat.letter,
    'receipt': const PdfPageFormat(200, 400),
    'invoice': const PdfPageFormat(210, 350),
  };

  // تحميل الخط العربي
  static Future<pw.Font> _loadArabicFont() async {
    try {
      final fontData = await rootBundle
          .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // إذا فشل تحميل الخط العربي، استخدم الخط الافتراضي
      return pw.Font.helvetica();
    }
  }

  // دالة مساعدة لإنشاء نص مع الخط العربي
  static pw.TextStyle _getArabicTextStyle(pw.Font arabicFont, double fontSize,
      {pw.FontWeight? fontWeight, PdfColor? color}) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      font: arabicFont,
    );
  }

  // دالة مساعدة للتحقق من صحة القيم الرقمية
  static bool _isValidNumber(num value) {
    return !value.isNaN && !value.isInfinite;
  }

  // دالة مساعدة لتنظيف القيم الرقمية
  static double _cleanNumber(num value, {double defaultValue = 0.0}) {
    if (!_isValidNumber(value)) {
      return defaultValue;
    }
    return value.toDouble();
  }

  // دالة مساعدة لتقسيم النص الطويل
  static List<String> _splitLongText(String text, int maxLength) {
    if (text.length <= maxLength) return [text];

    List<String> parts = [];
    int start = 0;

    while (start < text.length) {
      int end = start + maxLength;
      if (end > text.length) end = text.length;

      // محاولة تقسيم عند مسافة أو فاصلة
      if (end < text.length) {
        int lastSpace = text.lastIndexOf(' ', end);
        if (lastSpace > start) {
          end = lastSpace;
        }
      }

      parts.add(text.substring(start, end).trim());
      start = end;
    }

    return parts;
  }

  // دالة مساعدة لضمان عدم انقسام الكلمات
  static pw.Widget _buildSafeText(String text, pw.TextStyle style,
      {pw.TextAlign? textAlign, int maxLength = 30}) {
    final parts = _splitLongText(text, maxLength);

    if (parts.length == 1) {
      return pw.Text(text, style: style, textAlign: textAlign);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: parts
          .map((part) => pw.Text(part, style: style, textAlign: textAlign))
          .toList(),
    );
  }

  static Future<Uint8List> generate({
    required String shopName,
    required String? phone,
    required String? address,
    String? description, // وصف المحل
    required List<Map<String, Object?>> items,
    required String paymentType,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    DateTime? dueDate,
    String pageFormat = 'thermal_80', // افتراضي طابعة حرارية 80mm
    bool showLogo = true,
    bool showBarcode = true,
    String? invoiceNumber, // رقم الفاتورة من قاعدة البيانات
    List<Map<String, Object?>>? installments, // معلومات الأقساط
    double? totalDebt, // إجمالي الدين
    double? downPayment, // المبلغ المقدم
    double? couponDiscount, // خصم الكوبون
    double? subtotal, // الإجمالي قبل الكوبون
  }) async {
    // فحص البيانات قبل المعالجة (للتشخيص فقط)
    // يمكن إزالة هذا الجزء بعد التأكد من استقرار النظام

    final doc = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final finalInvoiceNumber = invoiceNumber ?? _generateInvoiceNumber();

    // تحميل الخط العربي
    final arabicFont = await _loadArabicFont();

    // حساب الإجمالي قبل الكوبون
    double calculatedSubtotal = 0.0;
    for (final it in items) {
      final basePrice = _cleanNumber(it['price'] as num, defaultValue: 0.0);
      final quantity = _cleanNumber(it['quantity'] as num, defaultValue: 0.0);
      final discountPercent =
          _cleanNumber((it['discount_percent'] ?? 0) as num, defaultValue: 0.0)
              .clamp(0, 100);
      final price = basePrice * (1 - (discountPercent / 100));
      calculatedSubtotal += price * quantity;
    }

    // استخدام subtotal الممرر أو المحسوب
    final finalSubtotal = subtotal ?? calculatedSubtotal;
    final finalCouponDiscount = couponDiscount ?? 0.0;

    // حساب الإجمالي النهائي
    double total =
        (finalSubtotal - finalCouponDiscount).clamp(0.0, double.infinity);

    // تحديد نوع الورق
    final format = _pageFormats[pageFormat] ?? PdfPageFormat.roll80;

    // إضافة الصفحات مع دعم التقسيم
    _addPagesWithPagination(
        doc,
        items,
        shopName,
        phone,
        address,
        description,
        finalInvoiceNumber,
        date,
        paymentType,
        dueDate,
        customerName,
        customerPhone,
        customerAddress,
        total,
        format,
        arabicFont,
        installments: installments,
        totalDebt: totalDebt,
        downPayment: downPayment,
        couponDiscount: finalCouponDiscount,
        subtotal: finalSubtotal);

    return doc.save();
  }

  // إضافة الصفحات مع دعم التقسيم
  static void _addPagesWithPagination(
      pw.Document doc,
      List<Map<String, Object?>> items,
      String shopName,
      String? phone,
      String? address,
      String? description,
      String invoiceNumber,
      String date,
      String paymentType,
      DateTime? dueDate,
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      double total,
      PdfPageFormat format,
      pw.Font arabicFont,
      {List<Map<String, Object?>>? installments,
      double? totalDebt,
      double? downPayment,
      double? couponDiscount,
      double? subtotal}) {
    // إذا كان هناك أقساط، أنشئ صفحات منفصلة للأقساط أولاً
    if (installments != null &&
        installments.isNotEmpty &&
        paymentType == 'installment') {
      _addInstallmentPages(
          doc,
          shopName,
          phone,
          address,
          description,
          invoiceNumber,
          date,
          customerName,
          customerPhone,
          customerAddress,
          format,
          arabicFont,
          installments,
          totalDebt,
          downPayment);
    }

    // ثم أضف صفحات المنتجات
    _addProductPages(
        doc,
        items,
        shopName,
        phone,
        address,
        description,
        invoiceNumber,
        date,
        paymentType,
        dueDate,
        customerName,
        customerPhone,
        customerAddress,
        total,
        format,
        arabicFont,
        installments: installments,
        totalDebt: totalDebt,
        downPayment: downPayment,
        couponDiscount: couponDiscount,
        subtotal: subtotal);
  }

  // إضافة صفحات الأقساط
  static void _addInstallmentPages(
      pw.Document doc,
      String shopName,
      String? phone,
      String? address,
      String? description,
      String invoiceNumber,
      String date,
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      PdfPageFormat format,
      pw.Font arabicFont,
      List<Map<String, Object?>> installments,
      double? totalDebt,
      double? downPayment) {
    // حساب عدد الأقساط التي يمكن عرضها في الصفحة الواحدة
    final maxInstallmentsPerPage = _calculateMaxInstallmentsPerPage(format);

    // تقسيم الأقساط على الصفحات
    final pages = <List<Map<String, Object?>>>[];
    for (int i = 0; i < installments.length; i += maxInstallmentsPerPage) {
      final end = (i + maxInstallmentsPerPage < installments.length)
          ? i + maxInstallmentsPerPage
          : installments.length;
      pages.add(installments.sublist(i, end));
    }

    // إضافة كل صفحة أقساط
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final isFirstPage = pageIndex == 0;
      final isLastPage = pageIndex == pages.length - 1;
      final pageInstallments = pages[pageIndex];

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin:
              const pw.EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
          build: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Container(
                  width: format.width * 0.8,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // مساحة فارغة من الأعلى
                      pw.SizedBox(height: format.width < 100 ? 12 : 8),

                      // Header Section - رأس الفاتورة
                      if (isFirstPage) ...[
                        _buildHeader(shopName, phone, address, description,
                            invoiceNumber, date, format, arabicFont),
                        pw.SizedBox(height: 4),
                      ],

                      // Customer Info
                      if (isFirstPage) ...[
                        _buildCustomerInfoOnly(customerName, customerPhone,
                            customerAddress, arabicFont,
                            format: format),
                        pw.SizedBox(height: 4),
                      ],

                      // Installment Info
                      _buildInstallmentInfoForPage(
                          pageInstallments, totalDebt, downPayment, arabicFont,
                          format: format,
                          isFirstPage: isFirstPage,
                          isLastPage: isLastPage,
                          totalPages: pages.length),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // إضافة صفحات المنتجات
  static void _addProductPages(
      pw.Document doc,
      List<Map<String, Object?>> items,
      String shopName,
      String? phone,
      String? address,
      String? description,
      String invoiceNumber,
      String date,
      String paymentType,
      DateTime? dueDate,
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      double total,
      PdfPageFormat format,
      pw.Font arabicFont,
      {List<Map<String, Object?>>? installments,
      double? totalDebt,
      double? downPayment,
      double? couponDiscount,
      double? subtotal}) {
    // حساب عدد المنتجات التي يمكن عرضها في الصفحة الواحدة
    final maxItemsPerPage = _calculateMaxItemsPerPage(format);

    // فحص أن maxItemsPerPage صحيح
    if (maxItemsPerPage <= 0) {
      final safeMaxItems = 10;
      // تقسيم المنتجات على الصفحات بقيمة آمنة
      final pages = <List<Map<String, Object?>>>[];
      for (int i = 0; i < items.length; i += safeMaxItems) {
        final end =
            (i + safeMaxItems < items.length) ? i + safeMaxItems : items.length;
        pages.add(items.sublist(i, end));
      }
      // معالجة الصفحات بقيمة آمنة
      for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
        final isFirstPage = pageIndex == 0;
        final isLastPage = pageIndex == pages.length - 1;
        final pageItems = pages[pageIndex];

        doc.addPage(
          pw.Page(
            pageFormat: format,
            margin:
                const pw.EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
            build: (context) {
              return pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                  child: pw.Container(
                    width: format.width * 0.8,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // مساحة فارغة من الأعلى
                        pw.SizedBox(height: format.width < 100 ? 12 : 8),
                        // Header Section
                        if (isFirstPage) ...[
                          _buildHeader(shopName, phone, address, description,
                              invoiceNumber, date, format, arabicFont),
                          pw.SizedBox(height: 4),
                        ],

                        // Customer Info & Payment Type
                        if (isFirstPage) ...[
                          _buildCustomerAndPaymentInfo(
                              customerName,
                              customerPhone,
                              customerAddress,
                              paymentType,
                              dueDate,
                              arabicFont,
                              format: format,
                              installments:
                                  null, // لا نعرض الأقساط في صفحات المنتجات
                              totalDebt: null,
                              downPayment: null),
                          pw.SizedBox(height: 4),
                        ],

                        // Items Table
                        _buildItemsTable(pageItems, format, arabicFont,
                            startIndex: pageIndex * maxItemsPerPage,
                            couponDiscount: couponDiscount,
                            subtotal: subtotal),

                        // Total Section - قسم المجموع (في الصفحة الأخيرة فقط)
                        if (isLastPage) ...[
                          pw.SizedBox(height: 8),
                          _buildTotalSection(total, arabicFont,
                              allItems: items, format: format),
                          pw.SizedBox(height: 12),
                        ],

                        // Footer
                        if (isLastPage) ...[
                          pw.SizedBox(height: 8),
                          _buildFooter(format, arabicFont, invoiceNumber),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
      return;
    }

    // تقسيم المنتجات على الصفحات
    final pages = <List<Map<String, Object?>>>[];
    for (int i = 0; i < items.length; i += maxItemsPerPage) {
      final end = (i + maxItemsPerPage < items.length)
          ? i + maxItemsPerPage
          : items.length;
      pages.add(items.sublist(i, end));
    }

    // إضافة كل صفحة
    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final isFirstPage = pageIndex == 0;
      final isLastPage = pageIndex == pages.length - 1;
      final pageItems = pages[pageIndex];

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin:
              const pw.EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
          build: (context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Center(
                child: pw.Container(
                  width: format.width * 0.8,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // مساحة فارغة من الأعلى
                      pw.SizedBox(height: format.width < 100 ? 12 : 8),
                      // Header Section - رأس الفاتورة (في الصفحة الأولى فقط)
                      if (isFirstPage) ...[
                        _buildHeader(shopName, phone, address, description,
                            invoiceNumber, date, format, arabicFont),
                        pw.SizedBox(height: 4),
                      ],

                      // Customer Info & Payment Type - معلومات العميل ونوع الدفع (في الصفحة الأولى فقط)
                      if (isFirstPage) ...[
                        _buildCustomerAndPaymentInfo(
                            customerName,
                            customerPhone,
                            customerAddress,
                            paymentType,
                            dueDate,
                            arabicFont,
                            format: format,
                            installments:
                                null, // لا نعرض الأقساط في صفحات المنتجات
                            totalDebt: null,
                            downPayment: null),
                        pw.SizedBox(height: 4),
                      ],

                      // Items Table - جدول المنتجات
                      _buildItemsTable(pageItems, format, arabicFont,
                          startIndex: pageIndex * maxItemsPerPage,
                          couponDiscount: couponDiscount,
                          subtotal: subtotal),

                      pw.SizedBox(height: 8),

                      // Total Section - قسم المجموع (في الصفحة الأخيرة فقط)
                      if (isLastPage) ...[
                        _buildTotalSection(total, arabicFont,
                            allItems: items, format: format),
                        pw.SizedBox(height: 12),
                      ],

                      // Footer - تذييل الفاتورة
                      _buildFooter(format, arabicFont, invoiceNumber),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // بناء رأس الفاتورة
  static pw.Widget _buildHeader(
      String shopName,
      String? phone,
      String? address,
      String? description,
      String invoiceNumber,
      String date,
      PdfPageFormat format,
      pw.Font arabicFont) {
    // للطابعات الحرارية - رأس محسن ومضغوط
    if (format.width < 100) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.3),
          borderRadius: pw.BorderRadius.circular(1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // اسم المحل - حجم أصغر
            pw.Text(
              shopName,
              style: _getArabicTextStyle(arabicFont, 6,
                  fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
              maxLines: 1,
            ),

            // وصف المحل - حجم أصغر ومضغوط
            if (description != null && description.isNotEmpty) ...[
              pw.SizedBox(height: 0.5),
              pw.Text(
                description,
                style: _getArabicTextStyle(arabicFont, 4),
                textAlign: pw.TextAlign.center,
                maxLines: 1,
              ),
            ],

            pw.SizedBox(height: 0.5),

            // العنوان ورقم الفاتورة في سطر واحد مضغوط
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // العنوان (محاذاة لليمين) - حجم أصغر
                if (address != null && address.isNotEmpty)
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      address,
                      style: _getArabicTextStyle(arabicFont, 4),
                      textAlign: pw.TextAlign.right,
                      maxLines: 1,
                    ),
                  ),

                // رقم الفاتورة (محاذاة لليسار) - حجم أصغر
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'فاتورة: $invoiceNumber',
                    style: _getArabicTextStyle(arabicFont, 4,
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.left,
                    maxLines: 1,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 0.5),

            // رقم الهاتف والتاريخ في سطر واحد مضغوط
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // رقم الهاتف (محاذاة لليمين) - حجم أصغر
                if (phone != null && phone.isNotEmpty)
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      phone,
                      style: _getArabicTextStyle(arabicFont, 4),
                      textAlign: pw.TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                // التاريخ (محاذاة لليسار) - حجم أصغر
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    date,
                    style: _getArabicTextStyle(arabicFont, 4),
                    textAlign: pw.TextAlign.left,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // للأوراق الكبيرة - الرأس العادي
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // اسم المحل
          pw.Text(
            shopName,
            style: _getArabicTextStyle(arabicFont, _getFontSize(format, 14),
                fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          // وصف المحل (إذا كان موجود)
          if (description != null && description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              description,
              style: _getArabicTextStyle(arabicFont, _getFontSize(format, 10)),
              textAlign: pw.TextAlign.center,
              maxLines: 3,
            ),
          ],

          pw.SizedBox(height: 2),

          // معلومات المحل في صف واحد
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // العنوان (محاذاة لليمين)
              if (address != null && address.isNotEmpty)
                pw.Expanded(
                  child: pw.Text(
                    'العنوان : $address',
                    style: _getArabicTextStyle(
                        arabicFont, _getFontSize(format, 8)),
                    textAlign: pw.TextAlign.right,
                    maxLines: 1,
                  ),
                ),

              // رقم الفاتورة (محاذاة لليسار)
              pw.Expanded(
                child: pw.Text(
                  'رقم الفاتورة : $invoiceNumber',
                  style: _getArabicTextStyle(
                      arabicFont, _getFontSize(format, 8),
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 2),

          // رقم الهاتف والتاريخ في صف واحد
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // رقم الهاتف (محاذاة لليمين)
              if (phone != null && phone.isNotEmpty)
                pw.Expanded(
                  child: pw.Text(
                    'رقم الهاتف : $phone',
                    style: _getArabicTextStyle(
                        arabicFont, _getFontSize(format, 8)),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              // التاريخ (محاذاة لليسار)
              pw.Expanded(
                child: pw.Text(
                  'تاريخ: $date',
                  style:
                      _getArabicTextStyle(arabicFont, _getFontSize(format, 8)),
                  textAlign: pw.TextAlign.left,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء معلومات العميل فقط (بدون نوع الدفع)
  static pw.Widget _buildCustomerInfoOnly(String? customerName,
      String? customerPhone, String? customerAddress, pw.Font arabicFont,
      {PdfPageFormat? format}) {
    // للطابعات الحرارية - قسم مبسط
    if (format != null && format.width < 100) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(width: 0.5),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.Column(
          children: [
            // معلومات العميل
            if (customerName != null && customerName.isNotEmpty)
              pw.Text('العميل: $customerName',
                  style: _getArabicTextStyle(arabicFont, 6)),
            if (customerPhone != null && customerPhone.isNotEmpty)
              pw.Text('الهاتف: $customerPhone',
                  style: _getArabicTextStyle(arabicFont, 6)),
            if (customerAddress != null && customerAddress.isNotEmpty)
              pw.Text('العنوان: $customerAddress',
                  style: _getArabicTextStyle(arabicFont, 6)),
          ],
        ),
      );
    }

    // للأوراق الكبيرة - القسم العادي
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: [
          if (customerName != null && customerName.isNotEmpty)
            pw.Text('الاسم: $customerName',
                style: _getArabicTextStyle(arabicFont, 8)),
          if (customerPhone != null && customerPhone.isNotEmpty)
            pw.Text('الهاتف: $customerPhone',
                style: _getArabicTextStyle(arabicFont, 8)),
          if (customerAddress != null && customerAddress.isNotEmpty)
            pw.Text('العنوان: $customerAddress',
                style: _getArabicTextStyle(arabicFont, 8)),
        ],
      ),
    );
  }

  // بناء معلومات العميل ونوع الدفع في صف واحد
  static pw.Widget _buildCustomerAndPaymentInfo(
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      String paymentType,
      DateTime? dueDate,
      pw.Font arabicFont,
      {PdfPageFormat? format,
      List<Map<String, Object?>>? installments,
      double? totalDebt,
      double? downPayment}) {
    // تحديد نوع الدفع
    String paymentText = '';
    PdfColor paymentColor = PdfColors.black;
    switch (paymentType) {
      case 'cash':
        paymentText = 'نقداً';
        paymentColor = PdfColors.green;
        break;
      case 'credit':
        paymentText = 'آجل';
        paymentColor = PdfColors.orange;
        break;
      case 'installment':
        paymentText = 'تقسيط';
        paymentColor = PdfColors.blue;
        break;
    }

    // للطابعات الحرارية - قسم مبسط
    if (format != null && format.width < 100) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(width: 0.5),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.Column(
          children: [
            // معلومات العميل
            if (customerName != null && customerName.isNotEmpty)
              pw.Text('العميل: $customerName',
                  style: _getArabicTextStyle(arabicFont, 6)),
            if (customerPhone != null && customerPhone.isNotEmpty)
              pw.Text('الهاتف: $customerPhone',
                  style: _getArabicTextStyle(arabicFont, 6)),
            if (customerAddress != null && customerAddress.isNotEmpty)
              pw.Text('العنوان: $customerAddress',
                  style: _getArabicTextStyle(arabicFont, 6)),

            pw.SizedBox(height: 2),

            // نوع الدفع
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: paymentColor, width: 1),
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Text(
                paymentText,
                style: _getArabicTextStyle(arabicFont, 7,
                    fontWeight: pw.FontWeight.bold, color: paymentColor),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // معلومات الأقساط للطابعات الحرارية
            if (installments != null && installments.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              _buildInstallmentInfoCompact(
                  installments, totalDebt, downPayment, arabicFont),
            ],
          ],
        ),
      );
    }

    // للأوراق الكبيرة - القسم العادي
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // معلومات العميل في صف واحد
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    if (customerName != null && customerName.isNotEmpty)
                      pw.Text('الاسم: $customerName',
                          style: _getArabicTextStyle(arabicFont, 8)),
                    if (customerPhone != null && customerPhone.isNotEmpty)
                      pw.Text('الهاتف: $customerPhone',
                          style: _getArabicTextStyle(arabicFont, 8)),
                    if (customerAddress != null && customerAddress.isNotEmpty)
                      pw.Text('العنوان: $customerAddress',
                          style: _getArabicTextStyle(arabicFont, 8)),
                  ],
                ),
              ),

              pw.SizedBox(width: 8),

              // نوع الدفع
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: paymentColor, width: 1),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      paymentText,
                      style: _getArabicTextStyle(arabicFont, 9,
                          fontWeight: pw.FontWeight.bold, color: paymentColor),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (dueDate != null && paymentType != 'cash')
                      pw.Text(
                        DateFormat('yyyy-MM-dd').format(dueDate),
                        style: _getArabicTextStyle(arabicFont, 7,
                            color: paymentColor),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // معلومات الأقساط للأوراق الكبيرة
        if (installments != null && installments.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          _buildInstallmentInfoStandard(
              installments, totalDebt, downPayment, arabicFont),
        ],
      ],
    );
  }

  // حساب الحد الأقصى لعدد الأقساط في الصفحة الواحدة
  static int _calculateMaxInstallmentsPerPage(PdfPageFormat format) {
    // حساب المساحة المتاحة للأقساط
    final availableHeight = format.height - 120; // مساحة أقل للرأس والذيل
    final installmentHeight = 25; // ارتفاع كل قسط

    // فحص القيم للتأكد من صحتها
    if (availableHeight.isNaN ||
        availableHeight.isInfinite ||
        installmentHeight.isNaN ||
        installmentHeight.isInfinite ||
        installmentHeight <= 0) {
      return 5; // قيمة افتراضية آمنة
    }

    final result = (availableHeight / installmentHeight).floor();

    // التأكد من أن النتيجة صحيحة
    if (result.isNaN || result.isInfinite || result < 0) {
      return 5;
    }

    // تحديد حد أقصى مناسب حسب نوع الورق
    if (format.width < 100) {
      return result.clamp(1, 3); // طابعات حرارية - مساحة محدودة
    } else if (format.width < 200) {
      return result.clamp(1, 6); // طابعات حرارية 80mm
    } else if (format.width < 400) {
      return result.clamp(1, 10); // أوراق A5
    } else {
      return result.clamp(1, 15); // أوراق A4
    }
  }

  // حساب الحد الأقصى لعدد المنتجات في الصفحة الواحدة
  static int _calculateMaxItemsPerPage(PdfPageFormat format) {
    // حساب المساحة المتاحة للجدول
    final availableHeight =
        format.height - 180; // طرح مساحة أقل للرأس والذيل والمجموع (تحسين)
    final itemHeight = 35; // ارتفاع كل منتج (أكبر قليلاً)

    // فحص القيم للتأكد من صحتها
    if (availableHeight.isNaN ||
        availableHeight.isInfinite ||
        itemHeight.isNaN ||
        itemHeight.isInfinite ||
        itemHeight <= 0) {
      return 8; // قيمة افتراضية آمنة أقل
    }

    final result = (availableHeight / itemHeight).floor();

    // التأكد من أن النتيجة صحيحة
    if (result.isNaN || result.isInfinite || result < 0) {
      return 8;
    }

    // تحديد حد أقصى مناسب حسب نوع الورق
    if (format.width < 100) {
      return result.clamp(1, 4); // طابعات حرارية 58mm - مساحة محدودة جداً
    } else if (format.width < 200) {
      return result.clamp(1, 8); // طابعات حرارية 80mm - مساحة متوسطة
    } else if (format.width < 400) {
      return result.clamp(1, 12); // أوراق A5 - مساحة جيدة
    } else {
      return result.clamp(1, 20); // أوراق A4 - مساحة كبيرة
    }
  }

  // بناء جدول المنتجات العادي
  static pw.Widget _buildItemsTable(List<Map<String, Object?>> items,
      PdfPageFormat format, pw.Font arabicFont,
      {int startIndex = 0, double? couponDiscount, double? subtotal}) {
    // تحديد نوع الورق حسب العرض
    final width = format.width;

    // طابعة حرارية 58mm - عرض محدود جداً
    if (width < 70) {
      return _buildCompactThermalItemsTable(items, format, arabicFont,
          is58mm: true,
          startIndex: startIndex,
          couponDiscount: couponDiscount,
          subtotal: subtotal);
    }
    // طابعة حرارية 80mm - عرض متوسط
    else if (width < 120) {
      return _buildCompactThermalItemsTable(items, format, arabicFont,
          is58mm: false,
          startIndex: startIndex,
          couponDiscount: couponDiscount,
          subtotal: subtotal);
    }
    // ورقة A5 - عرض جيد
    else if (width < 450) {
      return _buildStandardItemsTable(items, format, arabicFont,
          isA5: true,
          startIndex: startIndex,
          couponDiscount: couponDiscount,
          subtotal: subtotal);
    }
    // ورقة A4 - عرض كبير
    else {
      return _buildStandardItemsTable(items, format, arabicFont,
          isA5: false,
          startIndex: startIndex,
          couponDiscount: couponDiscount,
          subtotal: subtotal);
    }
  }

  // بناء جدول مضغوط للطابعات الحرارية
  static pw.Widget _buildCompactThermalItemsTable(
      List<Map<String, Object?>> items,
      PdfPageFormat format,
      pw.Font arabicFont,
      {required bool is58mm,
      int startIndex = 0,
      double? couponDiscount,
      double? subtotal}) {
    return pw.Column(
      children: [
        // خط فاصل علوي - أرق
        pw.Container(
          width: double.infinity,
          height: 0.5,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(bottom: 2),
        ),

        // المنتجات - تخطيط مضغوط
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final e = entry.value;
          final name = e['name']?.toString() ?? '';
          final quantity =
              _cleanNumber(e['quantity'] as num, defaultValue: 0.0);
          final basePrice = _cleanNumber(e['price'] as num, defaultValue: 0.0);
          final discountPercent = _cleanNumber(
                  (e['discount_percent'] ?? 0) as num,
                  defaultValue: 0.0)
              .clamp(0, 100);
          final priceAfterDiscount = basePrice * (1 - (discountPercent / 100));

          // حساب السعر بعد الكوبون
          var lineTotalBeforeCoupon = priceAfterDiscount * quantity;
          var lineTotal = lineTotalBeforeCoupon;
          if (couponDiscount != null &&
              couponDiscount > 0 &&
              subtotal != null &&
              subtotal > 0) {
            final couponDiscountRatio = couponDiscount / subtotal;
            lineTotal = lineTotalBeforeCoupon * (1 - couponDiscountRatio);
          }

          final qty = quantity.isFinite ? quantity.toInt() : 0;

          // تقصير اسم المنتج أكثر للطابعات الحرارية
          String shortName = name;
          final maxLength = is58mm ? 12 : 18;
          if (name.length > maxLength) {
            shortName = '${name.substring(0, maxLength)}...';
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // اسم المنتج مع التسلسل
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // التسلسل - حجم أصغر
                  pw.Text(
                    '${startIndex + index + 1}.',
                    style: _getArabicTextStyle(arabicFont, is58mm ? 4 : 5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600),
                    textAlign: pw.TextAlign.left,
                  ),
                  // اسم المنتج - حجم أصغر
                  pw.Expanded(
                    child: pw.Text(
                      shortName,
                      style: _getArabicTextStyle(arabicFont, is58mm ? 5 : 6,
                          fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              // تفاصيل السعر والكمية - مضغوط
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // السعر الأصلي
                  pw.Text(
                    'أصلي: ${Formatters.currencyIQD(basePrice * qty)}',
                    style: _getArabicTextStyle(arabicFont, is58mm ? 3 : 4,
                        color: PdfColors.grey600),
                    textAlign: pw.TextAlign.right,
                  ),
                  // السعر بعد الخصم
                  if (discountPercent > 0)
                    pw.Text(
                      'بعد خصم ${discountPercent.toStringAsFixed(0)}%: ${Formatters.currencyIQD(lineTotalBeforeCoupon)}',
                      style: _getArabicTextStyle(arabicFont, is58mm ? 3 : 4,
                          color: PdfColors.blue700),
                      textAlign: pw.TextAlign.right,
                    ),
                  // السعر بعد الكوبون
                  if (couponDiscount != null &&
                      couponDiscount > 0 &&
                      subtotal != null &&
                      subtotal > 0 &&
                      lineTotal < lineTotalBeforeCoupon)
                    pw.Text(
                      'بعد كوبون: ${Formatters.currencyIQD(lineTotal)}',
                      style: _getArabicTextStyle(arabicFont, is58mm ? 4 : 5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700),
                      textAlign: pw.TextAlign.right,
                    )
                  else
                    pw.Text(
                      'الإجمالي: ${Formatters.currencyIQD(lineTotal)}',
                      style: _getArabicTextStyle(arabicFont, is58mm ? 4 : 5,
                          fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.right,
                    ),
                ],
              ),

              // خط فاصل - أرق
              if (index < items.length - 1)
                pw.Container(
                  width: double.infinity,
                  height: 0.3,
                  color: PdfColors.grey300,
                  margin: const pw.EdgeInsets.symmetric(vertical: 1),
                ),
            ],
          );
        }),

        // خط فاصل سفلي - أرق
        pw.Container(
          width: double.infinity,
          height: 0.5,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(top: 2),
        ),
      ],
    );
  }

  // بناء جدول عادي للأوراق الكبيرة
  static pw.Widget _buildStandardItemsTable(List<Map<String, Object?>> items,
      PdfPageFormat format, pw.Font arabicFont,
      {required bool isA5,
      int startIndex = 0,
      double? couponDiscount,
      double? subtotal}) {
    // تكييف أبعاد الأعمدة حسب حجم الورق
    Map<int, pw.TableColumnWidth> columnWidths;
    double fontSize;
    double padding;

    if (isA5) {
      // ورقة A5
      columnWidths = {
        0: pw.FlexColumnWidth(1.4), // الإجمالي
        1: pw.FlexColumnWidth(1.4), // السعر
        2: pw.FlexColumnWidth(1), // الكمية
        3: pw.FlexColumnWidth(2.8), // المنتجات
        4: pw.FlexColumnWidth(0.7), // التسلسل
      };
      fontSize = 8;
      padding = 4;
    } else {
      // ورقة A4
      columnWidths = {
        0: pw.FlexColumnWidth(1.5), // الإجمالي
        1: pw.FlexColumnWidth(1.5), // السعر
        2: pw.FlexColumnWidth(1), // الكمية
        3: pw.FlexColumnWidth(3), // المنتجات
        4: pw.FlexColumnWidth(0.8), // التسلسل
      };
      fontSize = 9;
      padding = 6;
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(width: 0.5),
        columnWidths: columnWidths,
        children: [
          // Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              // الإجمالي (أول عمود من اليمين)
              pw.Padding(
                padding: pw.EdgeInsets.all(padding),
                child: pw.Text(
                  'الإجمالي',
                  style: _getArabicTextStyle(arabicFont, fontSize,
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // السعر
              pw.Padding(
                padding: pw.EdgeInsets.all(padding),
                child: pw.Text(
                  'السعر',
                  style: _getArabicTextStyle(arabicFont, fontSize,
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // الكمية
              pw.Padding(
                padding: pw.EdgeInsets.all(padding),
                child: pw.Text(
                  'الكمية',
                  style: _getArabicTextStyle(arabicFont, fontSize,
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // المنتجات
              pw.Padding(
                padding: pw.EdgeInsets.all(padding),
                child: pw.Text(
                  'المنتجات',
                  style: _getArabicTextStyle(arabicFont, fontSize,
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // التسلسل (آخر عمود من اليمين)
              pw.Padding(
                padding: pw.EdgeInsets.all(padding),
                child: pw.Text(
                  'ت',
                  style: _getArabicTextStyle(arabicFont, fontSize,
                      fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),

          // Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            final name = e['name']?.toString() ?? '';
            final quantity =
                _cleanNumber(e['quantity'] as num, defaultValue: 0.0);
            final basePrice =
                _cleanNumber(e['price'] as num, defaultValue: 0.0);
            final discountPercent = _cleanNumber(
                    (e['discount_percent'] ?? 0) as num,
                    defaultValue: 0.0)
                .clamp(0, 100);
            final priceAfterDiscount =
                basePrice * (1 - (discountPercent / 100));

            // حساب السعر بعد الكوبون
            var lineTotalBeforeCoupon = priceAfterDiscount * quantity;
            var lineTotal = lineTotalBeforeCoupon;
            if (couponDiscount != null &&
                couponDiscount > 0 &&
                subtotal != null &&
                subtotal > 0) {
              final couponDiscountRatio = couponDiscount / subtotal;
              lineTotal = lineTotalBeforeCoupon * (1 - couponDiscountRatio);
            }

            final qty = quantity.isFinite ? quantity.toInt() : 0;

            return pw.TableRow(
              decoration: pw.BoxDecoration(
                color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
              ),
              children: [
                // الإجمالي (أول عمود من اليمين)
                pw.Padding(
                  padding: pw.EdgeInsets.all(padding),
                  child: pw.Text(
                    NumberFormat.currency(
                      locale: 'ar_IQ',
                      symbol: '',
                      decimalDigits: 0,
                    ).format(lineTotal),
                    style: _getArabicTextStyle(arabicFont, fontSize,
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // السعر - عرض الأسعار الثلاثة
                pw.Padding(
                  padding: pw.EdgeInsets.all(padding),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // السعر الأصلي
                      pw.Text(
                        'أصلي: ${NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(basePrice * qty)}',
                        style: _getArabicTextStyle(arabicFont, fontSize - 1,
                            color: PdfColors.grey600),
                        textAlign: pw.TextAlign.center,
                      ),
                      // السعر بعد الخصم
                      if (discountPercent > 0)
                        pw.Text(
                          'بعد خصم: ${NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(lineTotalBeforeCoupon)}',
                          style: _getArabicTextStyle(arabicFont, fontSize - 1,
                              color: PdfColors.blue700),
                          textAlign: pw.TextAlign.center,
                        ),
                      // السعر بعد الكوبون
                      if (couponDiscount != null &&
                          couponDiscount > 0 &&
                          subtotal != null &&
                          subtotal > 0 &&
                          lineTotal < lineTotalBeforeCoupon)
                        pw.Text(
                          'بعد كوبون: ${NumberFormat.currency(locale: 'ar_IQ', symbol: '', decimalDigits: 0).format(lineTotal)}',
                          style: _getArabicTextStyle(arabicFont, fontSize,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700),
                          textAlign: pw.TextAlign.center,
                        )
                      else
                        pw.Text(
                          NumberFormat.currency(
                                  locale: 'ar_IQ', symbol: '', decimalDigits: 0)
                              .format(lineTotal),
                          style: _getArabicTextStyle(arabicFont, fontSize,
                              fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                    ],
                  ),
                ),
                // الكمية
                pw.Padding(
                  padding: pw.EdgeInsets.all(padding),
                  child: pw.Text(
                    qty.toString(),
                    style: _getArabicTextStyle(arabicFont, fontSize),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // المنتجات
                pw.Padding(
                  padding: pw.EdgeInsets.all(padding),
                  child: _buildSafeText(
                    name,
                    _getArabicTextStyle(arabicFont, fontSize),
                    textAlign: pw.TextAlign.center,
                    maxLength: 25,
                  ),
                ),
                // التسلسل (آخر عمود من اليمين)
                pw.Padding(
                  padding: pw.EdgeInsets.all(padding),
                  child: pw.Text(
                    (startIndex + index + 1).toString(),
                    style: _getArabicTextStyle(arabicFont, fontSize,
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // بناء قسم المجموع مثل الكاشيرات الحقيقية للطابعات الحرارية
  static pw.Widget _buildThermalTotalSection(double total, pw.Font arabicFont,
      {List<Map<String, Object?>>? allItems}) {
    // حساب مجموع الكمية
    int totalQuantity = 0;
    if (allItems != null) {
      for (final item in allItems) {
        final quantity =
            _cleanNumber(item['quantity'] as num, defaultValue: 0.0);
        totalQuantity += quantity.isFinite ? quantity.toInt() : 0;
      }
    }

    return pw.Column(
      children: [
        // خط فاصل علوي
        pw.Container(
          width: double.infinity,
          height: 0.5,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(bottom: 2),
        ),

        // مجموع الكمية - مضغوط
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'إجمالي الكمية:',
              style: _getArabicTextStyle(arabicFont, 6,
                  fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
            pw.Text(
              '$totalQuantity قطعة',
              style: _getArabicTextStyle(arabicFont, 6,
                  fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),

        pw.SizedBox(height: 2),

        // المجموع الكلي - مضغوط
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'المجموع الكلي:',
              style: _getArabicTextStyle(arabicFont, 7,
                  fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
            pw.Text(
              NumberFormat.currency(
                locale: 'ar_IQ',
                symbol: AppStrings.currency,
                decimalDigits: 0,
              ).format(total),
              style: _getArabicTextStyle(arabicFont, 8,
                  fontWeight: pw.FontWeight.bold, color: PdfColors.red),
              textAlign: pw.TextAlign.left,
            ),
          ],
        ),

        // خط فاصل سفلي
        pw.Container(
          width: double.infinity,
          height: 0.5,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(top: 2),
        ),
      ],
    );
  }

  // بناء قسم المجموع
  static pw.Widget _buildTotalSection(double total, pw.Font arabicFont,
      {List<Map<String, Object?>>? allItems, PdfPageFormat? format}) {
    // للطابعات الحرارية - استخدام القسم المبسط
    if (format != null && format.width < 100) {
      return _buildThermalTotalSection(total, arabicFont, allItems: allItems);
    }

    // حساب مجموع الكمية
    int totalQuantity = 0;
    if (allItems != null) {
      for (final item in allItems) {
        final quantity =
            _cleanNumber(item['quantity'] as num, defaultValue: 0.0);
        totalQuantity += quantity.isFinite ? quantity.toInt() : 0;
      }
    }

    // تحديد نوع الورق وتكييف الأبعاد
    final isMediumPaper =
        format != null && format.width >= 100 && format.width < 200;

    double fontSize = isMediumPaper ? 9 : 11;
    double padding = isMediumPaper ? 6 : 8;

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: pw.EdgeInsets.all(padding * 0.6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        children: [
          // عنوان مضغوط
          pw.Text(
            'ملخص الفاتورة',
            style: _getArabicTextStyle(arabicFont, fontSize,
                fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: padding * 0.4),

          // صف معلومات الكمية - مضغوط
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الكمية:',
                style: _getArabicTextStyle(arabicFont, fontSize - 1,
                    fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                '$totalQuantity قطعة',
                style: _getArabicTextStyle(arabicFont, fontSize - 1,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
                textAlign: pw.TextAlign.left,
              ),
            ],
          ),

          pw.SizedBox(height: padding * 0.3),

          // صف المجموع الكلي - مضغوط
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'المجموع الكلي:',
                style: _getArabicTextStyle(arabicFont, fontSize,
                    fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
              pw.Text(
                NumberFormat.currency(
                  locale: 'ar_IQ',
                  symbol: AppStrings.currency,
                  decimalDigits: 0,
                ).format(total),
                style: _getArabicTextStyle(arabicFont, fontSize + 1,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                textAlign: pw.TextAlign.left,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء تذييل الفاتورة
  static pw.Widget _buildFooter(
      PdfPageFormat format, pw.Font arabicFont, String invoiceNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // خط فاصل
        pw.Container(
          height: 1,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20),
        ),

        pw.SizedBox(height: 8),

        // رسالة شكر
        pw.Text(
          AppStrings.thankYou,
          style: _getArabicTextStyle(arabicFont, _getFontSize(format, 10),
              fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        // معلومات إضافية
        pw.Text(
          'نشكركم لاختياركم خدماتنا',
          style: _getArabicTextStyle(arabicFont, _getFontSize(format, 8)),
          textAlign: pw.TextAlign.center,
        ),

        pw.SizedBox(height: 4),

        // رقم الفاتورة في التذييل
        pw.Text(
          'رقم الفاتورة: $invoiceNumber',
          style: _getArabicTextStyle(arabicFont, _getFontSize(format, 7),
              color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // تحديد حجم الخط حسب نوع الورق
  static double _getFontSize(PdfPageFormat format, double baseSize) {
    if (format.width <= 60 * PdfPageFormat.mm) {
      return baseSize * 0.8; // خط أصغر للطابعة الحرارية الصغيرة
    } else if (format.width <= 85 * PdfPageFormat.mm) {
      return baseSize; // حجم عادي للطابعة الحرارية 80mm
    } else {
      return baseSize * 1.2; // خط أكبر للأوراق العادية
    }
  }

  // توليد رقم فاتورة فريد
  static String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  // الحصول على أنواع الأوراق المتاحة
  static List<String> getAvailablePageFormats() {
    return _pageFormats.keys.toList();
  }

  // الحصول على معلومات نوع الورق
  static Map<String, dynamic> getPageFormatInfo(String formatName) {
    final format = _pageFormats[formatName];
    if (format == null) return {};

    return {
      'name': formatName,
      'width': format.width,
      'height': format.height,
      'description': _getFormatDescription(formatName),
    };
  }

  // وصف أنواع الأوراق
  static String _getFormatDescription(String formatName) {
    switch (formatName) {
      case '58':
        return 'طابعة حرارية 58mm - فواتير صغيرة ومضغوطة';
      case '80':
        return 'طابعة حرارية 80mm - فواتير عادية ومقروءة';
      case 'A4':
        return 'ورقة A4 - فواتير تفصيلية ومهنية';
      case 'A5':
        return 'ورقة A5 - فواتير متوسطة الحجم';
      // Legacy support
      case 'thermal_58':
        return 'طابعة حرارية 58mm - مناسبة للفواتير الصغيرة';
      case 'thermal_80':
        return 'طابعة حرارية 80mm - مناسبة للفواتير العادية';
      case 'a4':
        return 'ورقة A4 - مناسبة للفواتير التفصيلية';
      case 'a5':
        return 'ورقة A5 - مناسبة للفواتير المتوسطة';
      case 'letter':
        return 'ورقة Letter - مناسبة للفواتير الأمريكية';
      case 'receipt':
        return 'فاتورة صغيرة - مناسبة للفواتير السريعة';
      case 'invoice':
        return 'فاتورة عادية - مناسبة للفواتير الرسمية';
      default:
        return 'نوع غير معروف';
    }
  }

  // بناء معلومات الأقساط لصفحة منفصلة
  static pw.Widget _buildInstallmentInfoForPage(
      List<Map<String, Object?>> installments,
      double? totalDebt,
      double? downPayment,
      pw.Font arabicFont,
      {PdfPageFormat? format,
      required bool isFirstPage,
      required bool isLastPage,
      required int totalPages}) {
    final unpaidInstallments =
        installments.where((i) => (i['paid'] as int) == 0).toList();
    final paidInstallments =
        installments.where((i) => (i['paid'] as int) == 1).toList();

    // حساب المجموع الكلي (المبلغ المقدم + إجمالي الأقساط)
    final totalAmount = (downPayment ?? 0) + (totalDebt ?? 0);

    // للطابعات الحرارية - عرض مبسط
    if (format != null && format.width < 100) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          border: pw.Border.all(color: PdfColors.blue, width: 0.5),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'معلومات الأقساط',
              style: _getArabicTextStyle(arabicFont, 7,
                  fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
            ),
            pw.SizedBox(height: 2),

            // المجموع الكلي
            pw.Text(
              'المجموع الكلي: ${Formatters.currencyIQD(totalAmount)}',
              style: _getArabicTextStyle(arabicFont, 6,
                  fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
            pw.SizedBox(height: 1),

            // المبلغ المقدم
            if (downPayment != null && downPayment > 0)
              pw.Text(
                'المبلغ المقدم: ${Formatters.currencyIQD(downPayment)}',
                style:
                    _getArabicTextStyle(arabicFont, 6, color: PdfColors.green),
              ),

            // إجمالي الدين
            if (totalDebt != null && totalDebt > 0)
              pw.Text(
                'إجمالي الأقساط: ${Formatters.currencyIQD(totalDebt)}',
                style: _getArabicTextStyle(arabicFont, 6, color: PdfColors.red),
              ),

            pw.SizedBox(height: 2),

            // الأقساط المتبقية
            if (unpaidInstallments.isNotEmpty) ...[
              pw.Text(
                'الأقساط المتبقية:',
                style: _getArabicTextStyle(arabicFont, 6,
                    fontWeight: pw.FontWeight.bold),
              ),
              ...unpaidInstallments.map((installment) {
                final dueDate =
                    DateTime.parse(installment['due_date'] as String);
                final amount = (installment['amount'] as num).toDouble();
                final isOverdue = dueDate.isBefore(DateTime.now());

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 4, top: 1),
                  child: pw.Text(
                    '${DateFormat('dd/MM').format(dueDate)}: ${Formatters.currencyIQD(amount)}${isOverdue ? ' (متأخر)' : ''}',
                    style: _getArabicTextStyle(arabicFont, 5,
                        color: isOverdue ? PdfColors.red : PdfColors.black),
                  ),
                );
              }),
            ],

            // الأقساط المدفوعة
            if (paidInstallments.isNotEmpty)
              pw.Text(
                'مدفوع: ${paidInstallments.length}/${installments.length}',
                style:
                    _getArabicTextStyle(arabicFont, 5, color: PdfColors.green),
              ),
          ],
        ),
      );
    }

    // للأوراق الكبيرة - عرض مفصل
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'معلومات الأقساط',
                style: _getArabicTextStyle(arabicFont, 9,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // المجموع الكلي
                  pw.Text(
                    'المجموع الكلي: ${Formatters.currencyIQD(totalAmount)}',
                    style: _getArabicTextStyle(arabicFont, 8,
                        fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 2),
                  if (downPayment != null && downPayment > 0)
                    pw.Text(
                      'المبلغ المقدم: ${Formatters.currencyIQD(downPayment)}',
                      style: _getArabicTextStyle(arabicFont, 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green),
                    ),
                  if (totalDebt != null && totalDebt > 0)
                    pw.Text(
                      'إجمالي الأقساط: ${Formatters.currencyIQD(totalDebt)}',
                      style: _getArabicTextStyle(arabicFont, 8,
                          fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                    ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 4),

          // جدول الأقساط المتبقية
          if (unpaidInstallments.isNotEmpty) ...[
            pw.Text(
              'الأقساط المتبقية:',
              style: _getArabicTextStyle(arabicFont, 8,
                  fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
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
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        'تاريخ الاستحقاق',
                        style: _getArabicTextStyle(arabicFont, 7,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        'المبلغ',
                        style: _getArabicTextStyle(arabicFont, 7,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        'الحالة',
                        style: _getArabicTextStyle(arabicFont, 7,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // صفوف الأقساط
                ...unpaidInstallments.map((installment) {
                  final dueDate =
                      DateTime.parse(installment['due_date'] as String);
                  final amount = (installment['amount'] as num).toDouble();
                  final isOverdue = dueDate.isBefore(DateTime.now());

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          DateFormat('dd/MM/yyyy').format(dueDate),
                          style: _getArabicTextStyle(arabicFont, 6),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          Formatters.currencyIQD(amount),
                          style: _getArabicTextStyle(arabicFont, 6),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          isOverdue ? 'متأخر' : 'في الموعد',
                          style: _getArabicTextStyle(arabicFont, 6,
                              color:
                                  isOverdue ? PdfColors.red : PdfColors.green),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],

          pw.SizedBox(height: 4),

          // ملخص الأقساط
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الأقساط: ${installments.length}',
                style: _getArabicTextStyle(arabicFont, 7),
              ),
              pw.Text(
                'مدفوع: ${paidInstallments.length}',
                style:
                    _getArabicTextStyle(arabicFont, 7, color: PdfColors.green),
              ),
              pw.Text(
                'متبقي: ${unpaidInstallments.length}',
                style:
                    _getArabicTextStyle(arabicFont, 7, color: PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء معلومات الأقساط للطابعات الحرارية (مضغوط)
  static pw.Widget _buildInstallmentInfoCompact(
      List<Map<String, Object?>> installments,
      double? totalDebt,
      double? downPayment,
      pw.Font arabicFont) {
    final unpaidInstallments =
        installments.where((i) => (i['paid'] as int) == 0).toList();
    final paidInstallments =
        installments.where((i) => (i['paid'] as int) == 1).toList();

    // حساب المجموع الكلي (المبلغ المقدم + إجمالي الأقساط)
    final totalAmount = (downPayment ?? 0) + (totalDebt ?? 0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'معلومات الأقساط',
            style: _getArabicTextStyle(arabicFont, 7,
                fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
          ),
          pw.SizedBox(height: 2),

          // المجموع الكلي
          pw.Text(
            'المجموع الكلي: ${Formatters.currencyIQD(totalAmount)}',
            style: _getArabicTextStyle(arabicFont, 6,
                fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.SizedBox(height: 1),

          // المبلغ المقدم
          if (downPayment != null && downPayment > 0)
            pw.Text(
              'المبلغ المقدم: ${Formatters.currencyIQD(downPayment)}',
              style: _getArabicTextStyle(arabicFont, 6, color: PdfColors.green),
            ),

          // إجمالي الدين
          if (totalDebt != null && totalDebt > 0)
            pw.Text(
              'إجمالي الأقساط: ${Formatters.currencyIQD(totalDebt)}',
              style: _getArabicTextStyle(arabicFont, 6, color: PdfColors.red),
            ),

          pw.SizedBox(height: 2),

          // الأقساط المتبقية
          if (unpaidInstallments.isNotEmpty) ...[
            pw.Text(
              'الأقساط المتبقية:',
              style: _getArabicTextStyle(arabicFont, 6,
                  fontWeight: pw.FontWeight.bold),
            ),
            ...unpaidInstallments.take(3).map((installment) {
              final dueDate = DateTime.parse(installment['due_date'] as String);
              final amount = (installment['amount'] as num).toDouble();
              final isOverdue = dueDate.isBefore(DateTime.now());

              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 4, top: 1),
                child: pw.Text(
                  '${DateFormat('dd/MM').format(dueDate)}: ${Formatters.currencyIQD(amount)}${isOverdue ? ' (متأخر)' : ''}',
                  style: _getArabicTextStyle(arabicFont, 5,
                      color: isOverdue ? PdfColors.red : PdfColors.black),
                ),
              );
            }),
            if (unpaidInstallments.length > 3)
              pw.Text(
                '... و ${unpaidInstallments.length - 3} قسط آخر',
                style:
                    _getArabicTextStyle(arabicFont, 5, color: PdfColors.grey),
              ),
          ],

          // الأقساط المدفوعة
          if (paidInstallments.isNotEmpty)
            pw.Text(
              'مدفوع: ${paidInstallments.length}/${installments.length}',
              style: _getArabicTextStyle(arabicFont, 5, color: PdfColors.green),
            ),
        ],
      ),
    );
  }

  // بناء معلومات الأقساط للأوراق الكبيرة (مفصل)
  static pw.Widget _buildInstallmentInfoStandard(
      List<Map<String, Object?>> installments,
      double? totalDebt,
      double? downPayment,
      pw.Font arabicFont) {
    final unpaidInstallments =
        installments.where((i) => (i['paid'] as int) == 0).toList();
    final paidInstallments =
        installments.where((i) => (i['paid'] as int) == 1).toList();

    // حساب المجموع الكلي (المبلغ المقدم + إجمالي الأقساط)
    final totalAmount = (downPayment ?? 0) + (totalDebt ?? 0);

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue, width: 0.5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'معلومات الأقساط',
                style: _getArabicTextStyle(arabicFont, 9,
                    fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // المجموع الكلي
                  pw.Text(
                    'المجموع الكلي: ${Formatters.currencyIQD(totalAmount)}',
                    style: _getArabicTextStyle(arabicFont, 8,
                        fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                  ),
                  pw.SizedBox(height: 2),
                  if (downPayment != null && downPayment > 0)
                    pw.Text(
                      'المبلغ المقدم: ${Formatters.currencyIQD(downPayment)}',
                      style: _getArabicTextStyle(arabicFont, 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green),
                    ),
                  if (totalDebt != null && totalDebt > 0)
                    pw.Text(
                      'إجمالي الأقساط: ${Formatters.currencyIQD(totalDebt)}',
                      style: _getArabicTextStyle(arabicFont, 8,
                          fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                    ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 4),

          // جدول الأقساط المتبقية
          if (unpaidInstallments.isNotEmpty) ...[
            pw.Text(
              'الأقساط المتبقية:',
              style: _getArabicTextStyle(arabicFont, 8,
                  fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
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
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        'تاريخ الاستحقاق',
                        style: _getArabicTextStyle(arabicFont, 7,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        'المبلغ',
                        style: _getArabicTextStyle(arabicFont, 7,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text(
                        'الحالة',
                        style: _getArabicTextStyle(arabicFont, 7,
                            fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // صفوف الأقساط
                ...unpaidInstallments.map((installment) {
                  final dueDate =
                      DateTime.parse(installment['due_date'] as String);
                  final amount = (installment['amount'] as num).toDouble();
                  final isOverdue = dueDate.isBefore(DateTime.now());

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          DateFormat('dd/MM/yyyy').format(dueDate),
                          style: _getArabicTextStyle(arabicFont, 6),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          Formatters.currencyIQD(amount),
                          style: _getArabicTextStyle(arabicFont, 6),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          isOverdue ? 'متأخر' : 'في الموعد',
                          style: _getArabicTextStyle(arabicFont, 6,
                              color:
                                  isOverdue ? PdfColors.red : PdfColors.green),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],

          pw.SizedBox(height: 4),

          // ملخص الأقساط
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'إجمالي الأقساط: ${installments.length}',
                style: _getArabicTextStyle(arabicFont, 7),
              ),
              pw.Text(
                'مدفوع: ${paidInstallments.length}',
                style:
                    _getArabicTextStyle(arabicFont, 7, color: PdfColors.green),
              ),
              pw.Text(
                'متبقي: ${unpaidInstallments.length}',
                style:
                    _getArabicTextStyle(arabicFont, 7, color: PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
