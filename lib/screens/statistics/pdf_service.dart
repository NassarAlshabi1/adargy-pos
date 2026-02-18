import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../../models/entry.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  Future<void> generatePdfReport(
    BuildContext context,
    List<Entry> entries,
    double totalNetProfit,
    double totalEngineerProfit,
    double totalManagerProfit,
    double totalAmount,
    String filterType,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري إنشاء التقرير...')
            ],
          ),
        ),
      );

      final arabicFont = pw.Font.ttf(
        await rootBundle.load('lib/assets/fonts/cairo.ttf'),
      );
      final latinFont = pw.Font.ttf(
        await rootBundle.load('lib/assets/fonts/NotoNaskhArabic-Regular.ttf'),
      );
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          fontFallback: [latinFont],
        ),
      );

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd', 'ar').format(now);

      final highestProfit = entries.isNotEmpty
          ? entries.map((e) => e.netProfit).reduce((a, b) => a > b ? a : b)
          : 0.0;

      final profitPercentage = totalAmount > 0
          ? (totalNetProfit / totalAmount * 100).toStringAsFixed(1)
          : '0';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 15,
            marginBottom: 15,
            marginLeft: 20,
            marginRight: 20,
          ),
          build: (_) => [
            _buildPdfHeader(arabicFont, filterType, formattedDate),
            pw.SizedBox(height: 12),
            _buildPdfSummary(
              arabicFont,
              totalAmount,
              totalNetProfit,
              totalEngineerProfit,
              totalManagerProfit,
              entries.length,
              profitPercentage,
              highestProfit,
            ),
            pw.SizedBox(height: 12),
            if (entries.isNotEmpty) _buildPdfTable(arabicFont, entries),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/تقرير_الإحصائيات_$filterType.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);
      _showPdfOptions(context, file, filterType);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  pw.Widget _buildPdfHeader(
      pw.Font font, String filterType, String formattedDate) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('تقرير الإحصائيات',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: font,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 4),
          pw.Text('الفترة: $filterType',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(height: 2),
          pw.Text('تاريخ التقرير: $formattedDate',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: font, fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummary(
    pw.Font font,
    double totalAmount,
    double totalNetProfit,
    double totalEngineerProfit,
    double totalManagerProfit,
    int entriesCount,
    String profitPercentage,
    double highestProfit,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        children: [
          pw.Center(
            child: pw.Text('ملخص الإحصائيات',
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                )),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfStat(
                  'إجمالي المبيعات', _formatCurrency(totalAmount), font),
              _buildPdfStat(
                  'صافي الربح', _formatCurrency(totalNetProfit), font),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfStat(
                  'ربح المهندس', _formatCurrency(totalEngineerProfit), font),
              _buildPdfStat(
                  'ربح المدير', _formatCurrency(totalManagerProfit), font),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfStat('عدد العناصر', '$entriesCount', font),
              _buildPdfStat('نسبة الربح', '$profitPercentage%', font),
            ],
          ),
          if (entriesCount > 0) pw.SizedBox(height: 6),
          if (entriesCount > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfStat('أعلى ربح', _formatCurrency(highestProfit), font),
                _buildPdfStat('متوسط الربح',
                    _formatCurrency(totalNetProfit / entriesCount), font),
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable(pw.Font font, List<Entry> entries) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text('تفاصيل المعاملات',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              )),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey, width: 0.3),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('التاريخ', font),
                _buildTableHeader('الإجمالي', font),
                _buildTableHeader('الربح', font),
                _buildTableHeader('العنوان', font),
              ],
            ),
            ...entries.take(10).map((entry) => pw.TableRow(
                  children: [
                    _buildTableCell(
                        DateFormat('yyyy / MM / dd').format(entry.date), font),
                    _buildTableCell(_formatCurrency(entry.totalAmount), font),
                    _buildTableCell(_formatCurrency(entry.netProfit), font),
                    _buildTableCell((entry.item), font),
                  ],
                )),
          ],
        ),
        if (entries.length > 10)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'عرض ${entries.take(10).length} من أصل ${entries.length} عنصر',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.rtl,
        style: pw.TextStyle(
            font: font, fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, pw.Font font) {
    final regex = RegExp(
        r'[\u0600-\u06FF]+|[a-zA-Z0-9@._]+|[^a-zA-Z\u0600-\u06FF\s]+|\s+');
    final spans = <pw.InlineSpan>[];

    for (final match in regex.allMatches(text)) {
      final part = match.group(0)!;
      final isEnglish = RegExp(r'^[a-zA-Z0-9@._]+$').hasMatch(part);

      spans.add(
        pw.TextSpan(
          text: part,
          style: pw.TextStyle(font: font, fontSize: 8),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.centerRight,
      child: pw.RichText(
        textDirection: pw.TextDirection.rtl,
        text: pw.TextSpan(children: spans),
      ),
    );
  }

  pw.Widget _buildPdfStat(String label, String value, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: font,
              color: PdfColors.grey700,
              fontSize: 8,
            )),
        pw.SizedBox(height: 2),
        pw.Text(value,
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            )),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ar',
      symbol: 'ريال',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// ✅ هذه الدالة تعالج النصوص المختلطة (عربي + إنجليزي) بإضافة LTR Embedding
  String _processMixedText(String text) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(text);

    if (hasArabic && hasEnglish) {
      return text.replaceAllMapped(
        RegExp(r'([a-zA-Z0-9@._]+)'),
        (match) => '\u202A${match.group(0)}\u202C',
      );
    }
    return text;
  }

  Future<void> _showPdfOptions(
      BuildContext context, File pdfFile, String filterType) async {
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
                Text('تم إنشاء التقرير بنجاح',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('ماذا تريد أن تفعل بالتقرير؟',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _printPdf(pdfFile);
                      },
                      icon: const Icon(Icons.print),
                      label: Text('طباعة', style: TextStyle()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _savePdf(context, pdfFile, filterType);
                      },
                      icon: const Icon(Icons.save_alt),
                      label: Text('حفظ', style: TextStyle()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
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

  Future<void> _viewPdf(BuildContext context, File pdfFile) async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute<dynamic>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('تقرير الإحصائيات')),
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

  Future<void> _printPdf(File pdfFile) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => pdfFile.readAsBytes(),
      );
    } catch (e) {
      debugPrint('فشل طباعة الملف: $e');
    }
  }

  Future<void> _savePdf(
      BuildContext context, File pdfFile, String filterType) async {
    try {
      final selectedDirectory = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'اختر مجلد الحفظ');
      if (selectedDirectory != null) {
        final newPath = '$selectedDirectory/تقرير_الإحصائيات_$filterType.pdf';
        await pdfFile.copy(newPath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ التقرير بنجاح في المجلد المحدد',
                style: TextStyle()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ التقرير: $e', style: TextStyle()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
