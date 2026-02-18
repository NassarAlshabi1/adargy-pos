import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../../models/entry.dart';

class PdfReport {
  /// تحميل الخط العربي وتخزينه لإعادة الاستخدام
  static Future<pw.Font> _loadArabicFont() async {
    return pw.Font.ttf(await rootBundle.load('lib/assets/fonts/cairo.ttf'));
  }

  /// تنسيق القيمة لتظهر بدون كسور عشرية مع نص "ريال" على اليسار وعلامة السالب قبل المبلغ
  static String formatCurrency(double value) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final formattedValue =
        formatter.format(value.abs()); // إزالة علامة السالب من الرقم

    // إضافة علامة السالب قبل المبلغ إذا كانت القيمة سالبة
    if (value < 0) {
      return '-${formattedValue} ريال';
    } else {
      return '${formattedValue} ريال';
    }
  }

  /// دالة لمعالجة النص المختلط (عربي + إنجليزي) في PDF
  static String _processMixedText(String text) {
    // التحقق من وجود حروف عربية في النص
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    // التحقق من وجود حروف إنجليزية في النص
    bool hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(text);

    // إذا كان النص يحتوي على حروف عربية وإنجليزية معاً
    if (hasArabic && hasEnglish) {
      // إضافة علامة LRM (Left-to-Right Mark) قبل الحروف الإنجليزية
      String processedText = text;
      // إضافة LRM قبل كل مجموعة من الحروف الإنجليزية
      processedText = processedText.replaceAllMapped(
          RegExp(r'[a-zA-Z]+'), (match) => '\u200E${match.group(0)}\u200E');
      return processedText;
    }

    return text;
  }

  /// الدالة الرئيسية لتوليد وتصدير ملف PDF
  static Future<void> exportToPdf(
      BuildContext context, List<Entry> entries, String formattedDate) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'جاري إنشاء التقرير...',
                  style: TextStyle(),
                )
              ],
            ),
          );
        },
      );

      final arabicFont = await _loadArabicFont();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 15,
            marginBottom: 15,
            marginLeft: 20,
            marginRight: 20,
          ),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFont,
          ),
          textDirection: pw.TextDirection.rtl,
          header: (pw.Context context) =>
              _buildHeaderWithLogo(formattedDate, arabicFont),
          footer: (pw.Context context) => _buildPageFooter(context, arabicFont),
          build: (pw.Context context) => [
            _buildHeader(formattedDate, arabicFont, entries),
            pw.SizedBox(height: 10),
            _buildDataTable(entries, arabicFont),
            pw.SizedBox(height: 15),
            _buildFooter(entries, arabicFont),
            pw.SizedBox(height: 10),
          ],
        ),
      );

      // حفظ الملف مؤقتًا
      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/تقرير_يومي_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // عرض خيارات التعامل مع ملف PDF
      _showPdfOptions(context, file);
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة حدوث خطأ
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  /// بناء رأس الصفحات مع شعار وترويسة - بطراز أبيض وأسود أنيق
  static pw.Widget _buildHeaderWithLogo(
      String formattedDate, pw.Font arabicFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.3))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // الشعار - أصغر
          pw.Container(
            width: 50,
            height: 15,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'دفتر مهندس',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: arabicFont,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
          // تاريخ الطباعة - أصغر
          pw.Text(
            'تاريخ الطباعة: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 7,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تذييل الصفحات بشكل أبيض وأسود أنيق - أصغر
  static pw.Widget _buildPageFooter(pw.Context context, pw.Font arabicFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3),
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: PdfColors.black, width: 0.3))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // رقم الصفحة - أصغر
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 6,
              color: PdfColors.black,
            ),
          ),
          // معلومات التقرير - أصغر
          pw.Text(
            'دفتر مهندس | ${DateFormat('yyyy/MM/dd').format(DateTime.now())}',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 6,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء رأس التقرير مع التاريخ والعنوان الرئيسي - أصغر وأبسط
  static pw.Widget _buildHeader(
      String formattedDate, pw.Font arabicFont, List<Entry> entries) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey200, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // عنوان التقرير - أصغر
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Text(
                'تقرير يومي',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),
            // بيانات التقرير - أبسط
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _processMixedText('التاريخ: $formattedDate'),
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    _processMixedText('عدد العناصر: ${entries.length}'),
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء جدول البيانات الرئيسي - أصغر وأكثر ملاءمة للطباعة
  static pw.Widget _buildDataTable(List<Entry> entries, pw.Font arabicFont) {
    // عنوان الجدول - أصغر
    final tableHeader = pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        'معاملات اليوم',
        style: pw.TextStyle(
          font: arabicFont,
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.right,
      ),
    );

    // عناوين الأعمدة
    final headers = ['الربح', 'سعر القطعة', 'المبلغ', 'الصنف', '#'];

    // تحضير بيانات الجدول مع ترقيم الصفوف
    final List<List<dynamic>> dataRows = [];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      dataRows.add([
        _processMixedText(formatCurrency(entry.netProfit)),
        _processMixedText(formatCurrency(entry.piecePrice)),
        _processMixedText(formatCurrency(entry.totalAmount)),
        (entry.item),
        _processMixedText('${i + 1}'),
      ]);
    }

    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          tableHeader,
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.3),
              headers: headers,
              data: dataRows,
              headerStyle: pw.TextStyle(
                font: arabicFont,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellStyle: pw.TextStyle(
                font: arabicFont,
                color: PdfColors.black,
                fontSize: 9,
              ),
              cellHeight: 20,
              cellAlignments: {
                0: pw.Alignment.centerRight,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellPadding: const pw.EdgeInsets.all(3),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء تذييل التقرير مع الملخص والإجماليات - أصغر وأبسط
  static pw.Widget _buildFooter(List<Entry> entries, pw.Font arabicFont) {
    final double totalAmount =
        entries.fold(0, (sum, entry) => sum + entry.totalAmount);
    final double totalNetProfit =
        entries.fold(0, (sum, entry) => sum + entry.netProfit);

    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey200, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // عنوان الملخص - أصغر
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              child: pw.Text(
                'ملخص اليوم',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),

            // بيانات الملخص - أبسط
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
              ),
              child: pw.Column(
                children: [
                  // إجمالي المبيعات
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'إجمالي المبيعات:  ',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        _processMixedText(formatCurrency(totalAmount)),
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),

                  // إجمالي الربح
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'إجمالي الربح:  ',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        _processMixedText(formatCurrency(totalNetProfit)),
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),

                  // عدد العناصر
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'عدد العناصر:  ',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        _processMixedText('${entries.length}'),
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// إضافة خط فاصل بين الأقسام لتحسين العرض والتنظيم
  static pw.Widget _buildPageSeparator() {
    return pw.Container(
      height: 1,
      color: PdfColors.grey200,
      margin: const pw.EdgeInsets.symmetric(vertical: 20),
    );
  }

  /// الحصول على إصدار SDK للجهاز (خاص بأندرويد)
  static Future<int> _getAndroidSdkVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  /// طلب صلاحية الوصول للتخزين مع مراعاة متطلبات أندرويد 14 وما فوق
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkVersion();
      if (sdkInt >= 34) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        return status.isGranted;
      }
    }
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  /// عرض خيارات عرض وحفظ وطباعة ملف PDF
  static Future<void> _showPdfOptions(
      BuildContext context, File pdfFile) async {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم إنشاء التقرير بنجاح',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ماذا تريد أن تفعل بالتقرير؟',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // عرض التقرير
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _viewPdf(context, pdfFile);
                      },
                      icon: const Icon(Icons.visibility),
                      label: Text('عرض', style: TextStyle()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    // طباعة التقرير
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _printPdf(context, pdfFile);
                      },
                      icon: const Icon(Icons.print),
                      label: Text('طباعة', style: TextStyle()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    // حفظ التقرير
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _savePdf(context, pdfFile);
                      },
                      icon: const Icon(Icons.save_alt),
                      label: Text('حفظ', style: TextStyle()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// عرض ملف PDF
  static Future<void> _viewPdf(BuildContext context, File pdfFile) async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(
                'التقرير اليومي',
                style: TextStyle(),
              ),
            ),
            body: PdfPreview(
              build: (format) => pdfFile.readAsBytes(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل فتح الملف: $e')),
      );
    }
  }

  /// طباعة ملف PDF
  static Future<void> _printPdf(BuildContext context, File pdfFile) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfFile.readAsBytes(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل طباعة الملف: $e')),
      );
    }
  }

  /// حفظ ملف PDF في المجلد الذي يختاره المستخدم مع التعامل مع الأخطاء وإظهار رسائل مناسبة
  static Future<void> _savePdf(BuildContext context, File pdfFile) async {
    try {
      if (!await requestStoragePermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم منح إذن التخزين')),
        );
        return;
      }

      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلد حفظ التقرير',
      );
      if (selectedDirectory == null) {
        return;
      }

      final dateTime = DateTime.now();
      final formattedName = DateFormat('yyyyMMdd_HHmmss').format(dateTime);
      final fileName = 'تقرير_يومي_$formattedName.pdf';
      final newPath = '$selectedDirectory/$fileName';

      // نسخ الملف إلى المجلد المحدد
      await pdfFile.copy(newPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الحفظ بنجاح في: $newPath'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في الحفظ: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
