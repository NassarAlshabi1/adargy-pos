import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'package:daily/models/customer.dart';
import 'package:daily/screens/customer_screen/details_screen/utils/text_utils.dart';

/// Widget for displaying customer transactions in a table format
class TransactionTable extends StatelessWidget {
  final List<TransactionEntry> transactions;
  final Function(TransactionEntry) onEditTransaction;
  final Function(TransactionEntry) onDeleteTransaction;

  const TransactionTable({
    super.key,
    required this.transactions,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryColor = Colors.blue.shade700;

    // Calculate current total balance
    double totalBalance = transactions.fold(
        0.0, (sum, t) => sum + (t.isCredit ? t.amount : -t.amount));

    List<TableRow> transactionRows = [];

    // Display transactions in chronological order with newest first
    List<TransactionEntry> sortedTransactions = List.from(transactions);
    // Sort transactions by date from newest to oldest
    sortedTransactions.sort((a, b) => b.date.compareTo(a.date));

    for (var t in sortedTransactions) {
      // Display balance before current transaction
      transactionRows
          .add(_buildTransactionRow(t, totalBalance, isDark, context));
      // Adjust balance for next transaction
      totalBalance -= (t.isCredit ? t.amount : -t.amount);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Enable both vertical and horizontal scrolling
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Table(
                  columnWidths: const {
                    0: FractionColumnWidth(0.25),
                    1: FractionColumnWidth(0.25),
                    2: FractionColumnWidth(0.25),
                    3: FractionColumnWidth(0.25),
                  },
                  border: TableBorder.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: primaryColor),
                      children: [
                        _buildHeaderCell('التاريخ'),
                        _buildHeaderCell('التفاصيل'),
                        _buildHeaderCell('المبلغ'),
                        _buildHeaderCell('الرصيد'),
                      ],
                    ),
                    ...transactionRows,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  TableCell _buildHeaderCell(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  TableRow _buildTransactionRow(TransactionEntry t, double runningBalance,
      bool isDark, BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'ar', // Use Arabic locale
      symbol: t.currency, // Put currency name here
      decimalDigits: 0, // No decimal places
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      children: [
        _buildCell(
          DateFormat('yyyy-MM-dd').format(t.date),
          onTap: () => _showContextMenu(t, context),
          isDark: isDark,
        ),
        _buildCell(
          processMixedText(t.item),
          onTap: () => _showContextMenu(t, context),
          isDark: isDark,
        ),
        _buildCell(
          currencyFormat.format(t.amount), // Add currency only in amount
          color: t.isCredit
              ? (isDark ? Colors.green.shade300 : Colors.green)
              : (isDark ? Colors.red.shade300 : Colors.red),
          onTap: () => _showContextMenu(t, context),
          isDark: isDark,
        ),
        _buildCell(
          '${runningBalance < 0 ? '- ' : ''}${NumberFormat('#,##0', 'ar').format(runningBalance.abs())}',
          color: runningBalance >= 0
              ? (isDark ? Colors.green.shade300 : Colors.green)
              : (isDark ? Colors.red.shade300 : Colors.red),
          onTap: () => _showContextMenu(t, context),
          isDark: isDark,
        ),
      ],
    );
  }

  TableCell _buildCell(String text,
      {Color? color,
      FontWeight? fontWeight,
      VoidCallback? onTap,
      bool isDark = false}) {
    return TableCell(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            style: const TextStyle(
              color: color ?? (isDark ? Colors.white : Colors.black87),
              fontWeight: fontWeight ?? FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(
      TransactionEntry transaction, BuildContext context) async {
    final result = await showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 100, 100),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blue.shade700),
            title: Text('تعديل',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red.shade700),
            title: Text('حذف',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );

    if (result == 'edit') {
      onEditTransaction(transaction);
    } else if (result == 'delete') {
      onDeleteTransaction(transaction);
    }
  }
}
