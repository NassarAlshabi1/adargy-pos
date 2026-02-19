import 'dart:io';
import 'dart:convert' as convert;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CsvExporter {
  static Future<String?> exportRows(
      String filename, List<List<String>> rows) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف CSV',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (path == null) return null;
    // استخدم ترميز UTF-8 مع BOM + فواصل أسطر Windows لضمان عرض العربية في Excel
    final csv = rows.map((r) => r.map(_escape).join(',')).join('\r\n');
    final bytes = <int>[0xEF, 0xBB, 0xBF] + convert.utf8.encode(csv);
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  static String _escape(String input) {
    final needsQuotes =
        input.contains(',') || input.contains('"') || input.contains('\n');
    final escaped = input.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}

class PdfExporter {
  // يبني ملف PDF بسيط يحتوي على عنوان وجدول نصي (RTL جاهز باستخدام خط عربي)
  static Future<String?> exportSimpleTable({
    required String filename,
    required String title,
    required List<List<String>> rows,
  }) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (savePath == null) return null;

    // تحميل خط عربي لدعم النصوص من اليمين لليسار
    final fontData = await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border:
                        pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    children: rows
                        .map(
                          (r) => pw.TableRow(
                            // عكس ترتيب الأعمدة ليظهر البند يمين والقيمة يسار
                            children: r.reversed
                                .map(
                                  (c) => pw.Padding(
                                    padding: const pw.EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 8),
                                    child: pw.Text(
                                      c,
                                      style:
                                          pw.TextStyle(font: ttf, fontSize: 10),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();
    final file = File(savePath);
    await file.writeAsBytes(bytes, flush: true);
    return savePath;
  }

  // إنشاء مستند PDF وإرجاع البايتات مباشرة للطباعة أو المشاركة
  static Future<List<int>> buildDataTableBytes({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final fontData = await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: headers.reversed
                          .map((h) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: pw.Text(h,
                                    style: pw.TextStyle(
                                        font: ttf,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10)),
                              ))
                          .toList(),
                    ),
                    ...rows.map(
                      (r) => pw.TableRow(
                        children: r.reversed
                            .map(
                              (c) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: pw.Text(c,
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 10)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // تصدير قائمة مفاتيح/قيم (يعكس ترتيب العمودين تلقائياً للعرض RTL)
  static Future<String?> exportKeyValue({
    required String filename,
    required String title,
    required List<MapEntry<String, String>> items,
  }) async {
    final rows = <List<String>>[
      ['البند', 'القيمة'],
      ...items.map((e) => [e.key, e.value]),
    ];
    return exportSimpleTable(filename: filename, title: title, rows: rows);
  }

  // تصدير جدول بيانات مع رؤوس وأسطُر (RTL، لا يعكس الأعمدة لأنه قد يحتوي أكثر من عمودين)
  static Future<String?> exportDataTable({
    required String filename,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (savePath == null) return null;

    final fontData = await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      // اعكس ترتيب الرؤوس لعرض أول عمود في يمين الصفحة
                      children: headers.reversed
                          .map((h) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: pw.Text(h,
                                    style: pw.TextStyle(
                                        font: ttf,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10)),
                              ))
                          .toList(),
                    ),
                    ...rows.map(
                      (r) => pw.TableRow(
                        // اعكس ترتيب الصفوف ليتطابق مع الرؤوس RTL
                        children: r.reversed
                            .map(
                              (c) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 8),
                                child: pw.Text(c,
                                    style:
                                        pw.TextStyle(font: ttf, fontSize: 10)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await File(savePath).writeAsBytes(bytes, flush: true);
    return savePath;
  }

  // تصدير قائمة نصوص عادية (مثل سجل أو ملاحظات)
  static Future<String?> exportList({
    required String filename,
    required String title,
    required List<String> lines,
  }) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان حفظ ملف PDF',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (savePath == null) return null;

    final fontData = await rootBundle
        .load('assets/fonts/NotoSansArabic-VariableFont_wdth,wght.ttf');
    final ttf = pw.Font.ttf(fontData);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                ...lines.map((l) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(l,
                          style: pw.TextStyle(font: ttf, fontSize: 11)),
                    )),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await File(savePath).writeAsBytes(bytes, flush: true);
    return savePath;
  }
}
