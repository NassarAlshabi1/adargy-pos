import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../models/entry.dart';
import '../models/customer.dart';
import '../database/customer_database_helper.dart';
import 'dart:ui' as ui;
import 'package:dropdown_search/dropdown_search.dart';

/// Formatter مخصص لإدخال فواصل الآلاف (مثل: 10,000 أو 100,000)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // إزالة كل ما ليس أرقام
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.parse(newText);
    final formatted = _formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter مبسط للنص المختلط (عربي وإنجليزي)
class MixedTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // السماح بجميع أنواع النصوص بدون معالجة معقدة
    return newValue;
  }

  // دالة مساعدة لتنظيف النص عند الحفظ
  static String cleanText(String text) {
    return text.trim(); // فقط إزالة المسافات الزائدة
  }

  // دالة مساعدة لتحديد اتجاه النص
  static ui.TextDirection getTextDirection(String text) {
    // التحقق من وجود حروف عربية في النص
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    // التحقق من وجود حروف إنجليزية في النص
    bool hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(text);

    if (hasArabic && !hasEnglish) {
      return ui.TextDirection.rtl;
    } else if (!hasArabic && hasEnglish) {
      return ui.TextDirection.ltr;
    } else {
      // إذا كان النص مختلط، نستخدم RTL كافتراضي
      return ui.TextDirection.rtl;
    }
  }
}

class EntryFormHelper {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _piecePriceController = TextEditingController();
  final _customerController = TextEditingController();
  final _transportationController = TextEditingController();
  final _dailyExchangeController = TextEditingController();

  Customer? _selectedCustomer;
  List<Customer> _customers = [];

  // دالة تنسيق العملة بدون كسور عشرية (على سبيل المثال: "ريال 10,000")
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'ar',
      decimalDigits: 0, // بدون كسور عشرية
    );
    return formatter.format(value);
  }

  Future<void> _loadCustomers() async {
    final customerHelper = CustomerDatabaseHelper();
    _customers = await customerHelper.getCustomers();
  }

  void showEntryInputDialog(BuildContext context, {Entry? entry}) async {
    await _loadCustomers();

    if (entry != null) {
      _itemController.text = entry.item;
      _totalAmountController.text = entry.totalAmount.toString();
      _piecePriceController.text = entry.piecePrice.toString();
      _customerController.text = entry.customerName ?? '';
      _selectedCustomer = entry.customerId != null
          ? _customers.firstWhere((c) => c.id == entry.customerId,
              orElse: () => Customer(
                    id: entry.customerId!,
                    name: entry.customerName ?? '',
                    transactions: [],
                    currency: 'YER', // تمرير العملة الافتراضية
                  ))
          : null;
      _transportationController.text = entry.transportation.toString();
      _dailyExchangeController.text = entry.dailyExchange.toString();
    }

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              entry == null ? 'إضافة إدخال جديد' : 'تعديل الإدخال',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildFields(),
                ),
              ),
            ),
            actions: _buildActions(context, entry),
          ),
        );
      },
    );
  }

  List<Widget> _buildFields() {
    return [
      _buildTextField(
        controller: _itemController,
        label: 'التفاصيل',
        icon: Icons.shopping_cart,
        iconColor: Colors.blue,
      ),
      _buildTextField(
        controller: _totalAmountController,
        label: 'المبلغ الإجمالي',
        icon: Icons.attach_money,
        iconColor: Colors.green,
        keyboardType: TextInputType.number,
        inputFormatters: [ThousandsSeparatorInputFormatter()],
      ),
      _buildTextField(
        controller: _piecePriceController,
        label: 'سعر القطعة',
        icon: Icons.monetization_on,
        iconColor: Colors.orange,
        keyboardType: TextInputType.number,
      ),
      _buildTextField(
        controller: _dailyExchangeController,
        label: 'صرف اليوم',
        icon: Icons.account_balance_wallet,
        iconColor: Colors.purple,
        keyboardType: TextInputType.number,
      ),
      // إضافة حقل البحث التلقائي للعملاء
      _buildCustomerAutocomplete(),
      // جعل إدخال المواصلات اختياري
      _buildTextField(
        controller: _transportationController,
        label: 'المواصلات',
        icon: Icons.directions_car,
        iconColor: Colors.indigo,
        keyboardType: TextInputType.number,
        isRequired: false,
      ),
    ];
  }

  Widget _buildCustomerAutocomplete() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Autocomplete<Customer>(
        displayStringForOption: (Customer customer) => customer.name,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<Customer>.empty();
          }
          return _customers.where((Customer customer) {
            return customer.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (Customer customer) {
          _selectedCustomer = customer;
          _customerController.text = customer.name;
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          _customerController.text = controller.text;
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            textAlign: TextAlign.right,
            textDirection: ui.TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'المورد',
              prefixIcon: const Icon(
                Icons.person,
                color: Colors.teal,
                size: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              // لا يوجد أيقونة سهم أو زر مسح
            ),
            validator: (value) {
              return null;
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topRight,
            child: Material(
              elevation: 2.0,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 250,
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final Customer customer = options.elementAt(index);
                    return FutureBuilder<List<TransactionEntry>>(
                      future:
                          CustomerDatabaseHelper().getTransactions(customer.id),
                      builder: (context, snapshot) {
                        double balance = 0.0;
                        if (snapshot.hasData && snapshot.data != null) {
                          balance = snapshot.data!.fold(
                              0.0,
                              (sum, t) =>
                                  sum + (t.isCredit ? t.amount : -t.amount));
                        }
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          title: Text(
                            customer.name,
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11),
                          ),
                          subtitle: Text(
                            'الرصيد: ${formatCurrency(balance)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 9),
                          ),
                          onTap: () {
                            onSelected(customer);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, Entry? entry) {
    return [
      TextButton(
        onPressed: () {
          _clearControllers();
          Navigator.pop(context);
        },
        child: const Text(
          'إلغاء',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      ElevatedButton(
        onPressed: () => _handleSave(context, entry),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('حفظ', style: TextStyle(fontSize: 16)),
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.right,
        textDirection: ui.TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: iconColor,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          // إضافة تلميح للتفاصيل
        ),
        keyboardType: keyboardType ??
            (label == 'التفاصيل' ? TextInputType.text : TextInputType.number),
        inputFormatters: [
          ...?inputFormatters,
          // إزالة MixedTextInputFormatter من التفاصيل لتجنب المشاكل
          if (label != 'التفاصيل' && label != 'اسم العميل')
            MixedTextInputFormatter(),
        ],
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'الرجاء إدخال $label';
          }
          return null;
        },
        onChanged: (value) {
          // تحديث اتجاه النص بناءً على المحتوى للتفاصيل
          if (label == 'التفاصيل') {
            // لا حاجة لمعالجة خاصة للتفاصيل
          }
        },
      ),
    );
  }

  void _handleSave(BuildContext context, Entry? entry) async {
    if (_formKey.currentState!.validate()) {
      // إزالة الفواصل قبل تحويل النص إلى رقم
      String totalAmountText = _totalAmountController.text.replaceAll(',', '');

      // الحصول على نسبة المهندس من الإعدادات
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      final engineerPercentage = settingsProvider.engineerPercentage;

      // تحديد العملة بناءً على العميل المحدد
      String currency = 'ريال';
      if (_selectedCustomer != null) {
        final customerHelper = CustomerDatabaseHelper();
        final customerTransactions =
            await customerHelper.getTransactions(_selectedCustomer!.id);
        if (customerTransactions.isNotEmpty) {
          currency = customerTransactions.first.currency;
        }
      }

      final newEntry = Entry(
        id: entry?.id ?? const Uuid().v4(),
        item: _itemController.text.trim(), // تنظيف النص فقط
        totalAmount: double.parse(totalAmountText),
        piecePrice: double.parse(_piecePriceController.text),
        percentage: engineerPercentage,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name != null
            ? _selectedCustomer!.name.trim() // تنظيف النص فقط
            : null,
        customerCurrency: currency,
        transportation: double.tryParse(_transportationController.text) ?? 0.0,
        dailyExchange: double.tryParse(_dailyExchangeController.text) ?? 0.0,
        date: DateTime.now(),
      );

      final entryProvider = Provider.of<EntryProvider>(context, listen: false);
      if (entry == null) {
        await entryProvider.addEntry(newEntry);
      } else {
        await entryProvider.editEntry(entry.id, newEntry);
      }

      // إضافة معاملة للعميل المحدد إذا كان موجوداً
      if (_selectedCustomer != null) {
        final customerHelper = CustomerDatabaseHelper();
        final transaction = TransactionEntry(
          customerId: _selectedCustomer!.id,
          date: DateTime.now(),
          item: '${_itemController.text.trim()}', // تنظيف النص فقط
          amount: double.parse(_piecePriceController.text),
          currency: currency,
          isCredit: true,
        );
        await customerHelper.insertTransaction(transaction);
      }

      _clearControllers();
      Navigator.pop(context);
    }
  }

  void _clearControllers() {
    _itemController.clear();
    _totalAmountController.clear();
    _piecePriceController.clear();
    _customerController.clear();
    _transportationController.clear();
    _dailyExchangeController.clear();
    _selectedCustomer = null;
  }
}
