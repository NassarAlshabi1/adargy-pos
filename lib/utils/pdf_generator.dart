import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:alhaytham_trade/models/customer.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class PdfGenerator {
  // الحصول على عناوين الجدول باللغة العربية
  static Map<String, String> _getLabels() {
    return {
      'dateHeader': 'التاريخ',
      'descriptionHeader': 'التفاصيل',
      'amountHeader': 'المبلغ',
      'typeHeader': 'النوع',
      'balanceHeader': 'الرصيد',
      'creditType': 'له',
      'debitType': 'عليه',
      'reportTitle': 'تقرير حساب العميل',
      'customerName': 'اسم العميل',
      'reportDate': 'تاريخ التقرير',
      'transactionsCount': 'عدد المعاملات',
      'netBalance': 'الرصيد الصافي',
      'transactionsRecord': 'سجل المعاملات',
      'noTransactions': 'لا توجد معاملات لهذا العميل',
      'accountSummary': 'ملخص الحساب',
      'totalCredit': 'إجمالي له',
      'totalDebit': 'إجمالي عليه',
      'finalBalance': 'الرصيد النهائي',
      'customerSignature': 'توقيع العميل',
      'accountantSignature': 'توقيع المحاسب',
      'page': 'صفحة',
      'of': 'من',
    };
  }

  // تحميل الخطوط العربية
  static Future<Map<String, pw.Font>> _loadFonts() async {
    try {
      // تحميل خط Cairo للنصوص العادية
      final cairoFontData = await rootBundle.load('lib/assets/fonts/cairo.ttf');
      final cairoFont = pw.Font.ttf(cairoFontData.buffer.asByteData());

      // تحميل خط NotoNaskhArabic للرموز والعملة
      final notoFontData =
          await rootBundle.load('lib/assets/fonts/NotoNaskhArabic-Regular.ttf');
      final notoFont = pw.Font.ttf(notoFontData.buffer.asByteData());

      return {
        'cairo': cairoFont,
        'noto': notoFont,
      };
    } catch (e) {
      // استخدام خط افتراضي إذا فشلت المحاولة
      print('فشل تحميل الخطوط العربية: $e');
      final fallbackFont = pw.Font.helvetica();
      return {
        'cairo': fallbackFont,
        'noto': fallbackFont,
      };
    }
  }

  // بناء خلية عنوان في الجدول
  static pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  // بناء خلية في الجدول
  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    PdfColor color = PdfColors.black,
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          color: color,
          fontSize: 8,
        ),
      ),
    );
  }

  // دالة جديدة لبناء نص العملة مع خطين مختلفين
  static pw.Widget _buildCurrencyText(
      double amount, pw.Font cairoFont, pw.Font notoFont, String currency) {
    // تنسيق الرقم فقط بدون رمز العملة
    final numberFormatter = NumberFormat('#,##0', 'ar');
    final formattedNumber = numberFormatter.format(amount.abs());

    // تحديد رمز العملة بناءً على عملة العميل
    String currencySymbol;
    switch (currency.toLowerCase()) {
      case 'دولار':
      case 'usd':
      case 'dollar':
        currencySymbol = '\$';
        break;
      case 'يورو':
      case 'eur':
      case 'euro':
        currencySymbol = '€';
        break;
      case 'جنيه':
      case 'egp':
      case 'pound':
        currencySymbol = '£';
        break;
      case 'ر.س':
      case 'ريال سعودي':
      case 'sar':
        currencySymbol = 'ر.س';
        break;
      case 'ر.ي':
      case 'ريال يمني':
      case 'yer':
        currencySymbol = 'ر.ي';
        break;
      case 'محلي':
      default:
        currencySymbol = 'ر.س'; // تغيير الافتراضي إلى ر.س
        break;
    }

    String sign = '';
    if (amount < 0) {
      sign = '- ';
    }

    return pw.RichText(
      text: pw.TextSpan(
        children: [
          // علامة السالب (إن وجدت) بخط Cairo
          if (sign.isNotEmpty)
            pw.TextSpan(
              text: sign,
              style: pw.TextStyle(font: cairoFont, fontSize: 8),
            ),
          // الرقم بخط Cairo
          pw.TextSpan(
            text: formattedNumber,
            style: pw.TextStyle(font: cairoFont, fontSize: 8),
          ),
          // مسافة
          pw.TextSpan(
            text: ' ',
            style: pw.TextStyle(font: cairoFont, fontSize: 8),
          ),
          // رمز العملة بخط NotoNaskhArabic
          pw.TextSpan(
            text: currencySymbol,
            style: pw.TextStyle(font: notoFont, fontSize: 8),
          ),
        ],
      ),
    );
  }

  // دالة جديدة لبناء خلية العملة
  static pw.Widget _buildCurrencyCell(
    double amount,
    pw.Font cairoFont,
    pw.Font notoFont,
    String currency, {
    PdfColor color = PdfColors.black,
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: align,
      child: _buildCurrencyText(amount, cairoFont, notoFont, currency),
    );
  }

  // دالة لمعالجة النص المختلط (عربي + إنجليزي) في PDF
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

  // إنشاء تقرير PDF للعميل
  static Future<File> generateCustomerReport(Customer customer) async {
    try {
      // إعداد الخطوط
      final fonts = await _loadFonts();
      final cairoFont = fonts['cairo']!;
      final notoFont = fonts['noto']!;
      final latinFont =
          pw.Font.helvetica(); // Load Helvetica for Latin characters

      // الحصول على عناوين باللغة العربية
      final labels = _getLabels();

      // إنشاء مستند PDF
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: cairoFont,
          fontFallback: [notoFont, latinFont],
        ),
      );

      // الحصول على تاريخ اليوم بتنسيق بسيط
      final DateTime now = DateTime.now();
      final today = '${now.year}/${now.month}/${now.day}';

      // التأكد من وجود قائمة المعاملات
      final transactions =
          customer.transactions.isNotEmpty ? customer.transactions : [];

      // إجمالي له
      final totalCredit = transactions
          .where((t) => t.isCredit)
          .fold(0.0, (sum, t) => sum + t.amount);

      // إجمالي عليه
      final totalDebit = transactions
          .where((t) => !t.isCredit)
          .fold(0.0, (sum, t) => sum + t.amount);

      // صافي الرصيد
      final netBalance = totalCredit - totalDebit;

      // تحديد العملة من المعاملات (العملة الأكثر استخداماً أو افتراضي ر.س)
      String customerCurrency = 'ر.س';
      if (transactions.isNotEmpty) {
        // حساب تكرار كل عملة
        Map<String, int> currencyCount = {};
        for (var transaction in transactions) {
          currencyCount[transaction.currency] =
              (currencyCount[transaction.currency] ?? 0) + 1;
        }

        // اختيار العملة الأكثر استخداماً
        String mostUsedCurrency = 'ر.س';
        int maxCount = 0;
        for (var entry in currencyCount.entries) {
          if (entry.value > maxCount) {
            maxCount = entry.value;
            mostUsedCurrency = entry.key;
          }
        }

        customerCurrency = mostUsedCurrency;
      }

      // إضافة صفحة جديدة
      pdf.addPage(
        pw.MultiPage(
          // إعدادات الصفحة - أصغر
          pageFormat: PdfPageFormat.a4.copyWith(
            marginTop: 15,
            marginBottom: 15,
            marginLeft: 20,
            marginRight: 20,
          ),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return [
              // عنوان التقرير - أصغر
              pw.Center(
                child: pw.Text(
                  labels['reportTitle']!,
                  style: pw.TextStyle(
                    font: cairoFont,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // معلومات العميل - أصغر
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5, color: PdfColors.black),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${labels['customerName']}: ${customer.name}',
                          style: pw.TextStyle(font: cairoFont, fontSize: 10),
                        ),
                        pw.Text(
                          '${labels['reportDate']}: $today',
                          style: pw.TextStyle(font: cairoFont, fontSize: 8),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${labels['transactionsCount']}: ${transactions.length}',
                          style: pw.TextStyle(font: cairoFont, fontSize: 8),
                        ),
                        pw.Text(
                          'العملة: $customerCurrency',
                          style: pw.TextStyle(font: cairoFont, fontSize: 8),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${labels['netBalance']}: ${_formatCurrency(netBalance, customerCurrency)}',
                          style: pw.TextStyle(
                            font: cairoFont,
                            fontSize: 8,
                            color: netBalance >= 0
                                ? PdfColors.green
                                : PdfColors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // جدول المعاملات - أصغر
              pw.Text(
                labels['transactionsRecord']!,
                style: pw.TextStyle(
                    font: cairoFont,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),

              transactions.isEmpty
                  ? pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.grey, width: 0.5),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        labels['noTransactions']!,
                        style: pw.TextStyle(font: cairoFont, fontSize: 10),
                      ),
                    )
                  : pw.Table(
                      border: pw.TableBorder.all(
                          color: PdfColors.black, width: 0.3),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2), // التاريخ
                        1: const pw.FlexColumnWidth(2), // الرصيد
                        2: const pw.FlexColumnWidth(1), // النوع
                        3: const pw.FlexColumnWidth(2), // المبلغ
                        4: const pw.FlexColumnWidth(4), // البيان
                      },
                      children: [
                        // رأس الجدول - أصغر
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(
                              color: PdfColors.grey300,
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColors.black, width: 0.5))),
                          children: [
                            _buildTableHeader(labels['dateHeader']!, cairoFont),
                            _buildTableHeader(
                                labels['balanceHeader']!, cairoFont),
                            _buildTableHeader(labels['typeHeader']!, cairoFont),
                            _buildTableHeader(
                                labels['amountHeader']!, cairoFont),
                            _buildTableHeader(
                                labels['descriptionHeader']!, cairoFont),
                          ],
                        ),

                        // بيانات المعاملات
                        ...List.generate(transactions.length, (index) {
                          // ترتيب المعاملات من الأقدم للأحدث
                          final sortedTransactions =
                              List<TransactionEntry>.from(transactions)
                                ..sort((a, b) => a.date.compareTo(b.date));

                          final transaction = sortedTransactions[index];

                          // حساب الرصيد المتراكم
                          double runningBalance = 0;
                          for (int i = 0; i <= index; i++) {
                            final t = sortedTransactions[i];
                            runningBalance +=
                                (t.isCredit ? t.amount : -t.amount);
                          }

                          return pw.TableRow(
                            children: [
                              _buildTableCell(
                                DateFormat('yyyy-MM-dd')
                                    .format(transaction.date),
                                cairoFont,
                              ),
                              _buildCurrencyCell(
                                runningBalance,
                                cairoFont,
                                notoFont,
                                transaction.currency,
                                color: runningBalance >= 0
                                    ? PdfColors.green
                                    : PdfColors.red,
                              ),
                              _buildTableCell(
                                transaction.isCredit
                                    ? labels['creditType']!
                                    : labels['debitType']!,
                                cairoFont,
                                color: transaction.isCredit
                                    ? PdfColors.green
                                    : PdfColors.red,
                              ),
                              _buildCurrencyCell(
                                transaction.amount,
                                cairoFont,
                                notoFont,
                                transaction.currency,
                                color: transaction.isCredit
                                    ? PdfColors.green
                                    : PdfColors.red,
                              ),
                              _buildTableCell(
                                transaction.item,
                                cairoFont,
                                align: pw.Alignment.centerRight,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
              pw.SizedBox(height: 12),

              // ملخص الحساب - أصغر
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5, color: PdfColors.black),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text(
                        labels['accountSummary']!,
                        style: pw.TextStyle(
                            font: cairoFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '${labels['totalCredit']}: ',
                          style: pw.TextStyle(
                              font: cairoFont,
                              fontSize: 10,
                              color: PdfColors.green),
                        ),
                        _buildCurrencyCell(
                          totalCredit,
                          cairoFont,
                          notoFont,
                          customerCurrency,
                          color: PdfColors.green,
                        ),
                        pw.Text(
                          '${labels['totalDebit']}: ',
                          style: pw.TextStyle(
                              font: cairoFont,
                              fontSize: 10,
                              color: PdfColors.red),
                        ),
                        _buildCurrencyCell(
                          totalDebit,
                          cairoFont,
                          notoFont,
                          customerCurrency,
                          color: PdfColors.red,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          '${labels['finalBalance']}: ',
                          style: pw.TextStyle(
                            font: cairoFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: netBalance >= 0
                                ? PdfColors.green
                                : PdfColors.red,
                          ),
                        ),
                        _buildCurrencyCell(
                          netBalance,
                          cairoFont,
                          notoFont,
                          customerCurrency,
                          color:
                              netBalance >= 0 ? PdfColors.green : PdfColors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // توقيع وتذييل - أصغر
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 120,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Divider(),
                        pw.SizedBox(height: 3),
                        pw.Text(labels['customerSignature']!,
                            style: pw.TextStyle(font: cairoFont, fontSize: 8)),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 120,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Divider(),
                        pw.SizedBox(height: 3),
                        pw.Text(labels['accountantSignature']!,
                            style: pw.TextStyle(font: cairoFont, fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ];
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 6),
              child: pw.Text(
                '${labels['page']} ${context.pageNumber} ${labels['of']} ${context.pagesCount}',
                style: pw.TextStyle(font: cairoFont, fontSize: 8),
              ),
            );
          },
        ),
      );

      // حفظ ملف PDF
      final output = await getApplicationDocumentsDirectory();
      final String fileName =
          'تقرير_${customer.name}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('خطأ في إنشاء ملف PDF: $e');
      rethrow;
    }
  }

  // دالة تنسيق العملة البسيطة
  static String _formatCurrency(double amount, [String currency = 'محلي']) {
    final numberFormatter = NumberFormat('#,##0', 'ar');
    final formattedNumber = numberFormatter.format(amount.abs());

    // تحديد رمز العملة بناءً على عملة العميل
    String currencySymbol;
    switch (currency.toLowerCase()) {
      case 'دولار':
      case 'usd':
      case 'dollar':
        currencySymbol = '\$';
        break;
      case 'يورو':
      case 'eur':
      case 'euro':
        currencySymbol = '€';
        break;
      case 'جنيه':
      case 'egp':
      case 'pound':
        currencySymbol = '£';
        break;
      case 'ر.س':
      case 'ريال سعودي':
      case 'sar':
        currencySymbol = 'ر.س';
        break;
      case 'ر.ي':
      case 'ريال يمني':
      case 'yer':
        currencySymbol = 'ر.ي';
        break;
      case 'محلي':
      default:
        currencySymbol = 'ر.س'; // تغيير الافتراضي إلى ر.س
        break;
    }

    if (amount < 0) {
      return '- $formattedNumber $currencySymbol';
    } else {
      return '$formattedNumber $currencySymbol';
    }
  }
}
