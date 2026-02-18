import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import 'entry_form.dart'; // تأكد من استيراد الملف الصحيح

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entryProvider = Provider.of<EntryProvider>(context);
    final entries = entryProvider.entries;

    double totalNetProfit =
        entries.fold(0, (sum, entry) => sum + entry.netProfit);
    double totalEngineerProfit =
        entries.fold(0, (sum, entry) => sum + entry.engineerProfit);
    double totalManagerProfit =
        entries.fold(0, (sum, entry) => sum + entry.managerProfit);
    double totalAmount =
        entries.fold(0, (sum, entry) => sum + entry.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الدورية'),
        backgroundColor: Colors.blue.shade800,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton(context, 'أسبوعي', () {
                  entryProvider.filterEntries('weekly');
                }),
                _buildFilterButton(context, 'شهري', () {
                  entryProvider.filterEntries('monthly');
                }),
                _buildFilterButton(context, 'سنوي', () {
                  entryProvider.filterEntries('yearly');
                }),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatisticCard('صافي الربح', totalNetProfit),
                  const SizedBox(width: 10),
                  _buildStatisticCard('ربح المهندس', totalEngineerProfit),
                  const SizedBox(width: 10),
                  _buildStatisticCard('ربح المدير', totalManagerProfit),
                  const SizedBox(width: 10),
                  _buildStatisticCard('إجمالي المبالغ', totalAmount),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'التفاصيل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildEntryRow(context, entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade800,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildStatisticCard(String label, double value) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${value.toStringAsFixed(2)} ريال',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryRow(BuildContext context, Entry entry) {
    final entryFormHelper = EntryFormHelper(); // إنشاء كائن من EntryFormHelper

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        title: Text(entry.item),
        subtitle: Text(
            'المبلغ الإجمالي: ${entry.totalAmount.toStringAsFixed(2)} ريال'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                entryFormHelper.showEntryInputDialog(context,
                    entry: entry); // فتح مربع الحوار
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await Provider.of<EntryProvider>(context, listen: false)
                    .deleteEntry(entry.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الإدخال بنجاح'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
