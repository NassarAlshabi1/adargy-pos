import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:daily/models/customer.dart';

/// Widget for displaying customer account summary
class SummaryCard extends StatelessWidget {
  final List<TransactionEntry> transactions;

  const SummaryCard({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Calculate total balance
    final double totalBalance = transactions.fold(
        0.0, (sum, t) => sum + (t.isCredit ? t.amount : -t.amount));

    // Get currency from customer's last transaction
    String customerCurrency = 'ر.ي';
    if (transactions.isNotEmpty) {
      List<TransactionEntry> sortedTransactions = [...transactions];
      sortedTransactions.sort((a, b) => b.date.compareTo(a.date));
      customerCurrency = sortedTransactions.first.currency;
    }

    // Transaction counts
    final int transactionsCount = transactions.length;
    final int creditCount = transactions.where((t) => t.isCredit).length;
    final int debitCount = transactions.where((t) => !t.isCredit).length;

    // Balance color
    final balanceColor = totalBalance >= 0
        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
        : (isDark ? Colors.red.shade300 : Colors.red.shade700);

    // Card background gradient colors
    final List<Color> gradientColors = totalBalance >= 0
        ? [
            isDark ? Colors.green.shade900 : Colors.green.shade100,
            isDark ? Colors.green.shade800 : Colors.green.shade50
          ]
        : [
            isDark ? Colors.red.shade900 : Colors.red.shade100,
            isDark ? Colors.red.shade800 : Colors.red.shade50
          ];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ملخص الحساب',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$transactionsCount معاملة',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          Directionality(
            textDirection: ui.TextDirection.rtl,
            child: RichText(
              text: TextSpan(
                children: [
                  if (totalBalance < 0)
                    TextSpan(
                      text: '- ',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                  TextSpan(
                    text: '${totalBalance.abs().toStringAsFixed(0)} ',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  TextSpan(
                    text: customerCurrency,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Credit information (له)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.green.shade900.withOpacity(0.3)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward,
                        color: Colors.green.shade600, size: 14),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          textDirection: ui.TextDirection.rtl,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'له (',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '${transactions.where((t) => t.isCredit).fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(0)} $customerCurrency',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              TextSpan(
                                text: ')',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(creditCount.toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),

              // Debit information (عليه)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.shade900.withOpacity(0.3)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward,
                        color: Colors.red.shade600, size: 14),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          textDirection: ui.TextDirection.rtl,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'عليه (',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '${transactions.where((t) => !t.isCredit).fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(0)} $customerCurrency',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              TextSpan(
                                text: ')',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(debitCount.toString(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
