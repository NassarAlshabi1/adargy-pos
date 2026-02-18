import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:daily/utils/pdf_generator.dart';

/// Utility functions for PDF operations in the customer detail screen

/// Generate and save PDF report for a customer
Future<void> generateAndSavePdfReport(
  BuildContext context,
  dynamic customer,
  Function showPdfOptions,
) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'جاري إنشاء التقرير...',
                style: const TextStyle(),
              ),
            ],
          ),
        ),
      ),
    );

    // Generate PDF file
    final pdfFile = await PdfGenerator.generateCustomerReport(customer);

    // Close loading indicator
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Show PDF options
    await showPdfOptions(pdfFile);
  } catch (e) {
    // Close loading indicator in case of error
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء إنشاء التقرير: $e',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// View PDF file
Future<void> viewPdf(
    BuildContext context, File pdfFile, String customerName) async {
  Navigator.of(context).push(
    MaterialPageRoute<dynamic>(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(
            'تقرير $customerName',
            style: const TextStyle(),
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
}

/// Print PDF file
Future<void> printPdf(File pdfFile) async {
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdfFile.readAsBytes(),
  );
}

/// Save PDF file to downloads folder
Future<void> savePdfToDownloads(BuildContext context, File pdfFile) async {
  try {
    // Check for storage permissions
    if (await requestStoragePermission(context)) {
      // Get file name
      final fileName = pdfFile.path.split('/').last;

      // Copy file from app temp directory to downloads folder
      String? downloadsPath;

      if (Platform.isAndroid) {
        // Downloads path on Android
        final directory = Directory('/storage/emulated/0/Download');
        // Check if directory exists
        if (await directory.exists()) {
          downloadsPath = directory.path;
        } else {
          // Use documents folder if downloads folder doesn't exist
          final externalDir = await getExternalStorageDirectory();
          downloadsPath = externalDir?.path;
        }
      } else if (Platform.isWindows) {
        // Downloads path on Windows
        final downloadsDir = await getDownloadsDirectory();
        downloadsPath = downloadsDir?.path;
      }

      if (downloadsPath != null) {
        // Create new file path
        final newPath = '$downloadsPath/$fileName';

        // Copy file
        await pdfFile.copy(newPath);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم حفظ التقرير في مجلد التنزيلات',
                style: const TextStyle(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw 'لم يتم العثور على مجلد التنزيلات';
      }
    }
  } catch (e) {
    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل حفظ التقرير: $e',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Request storage access permissions
Future<bool> requestStoragePermission(BuildContext context) async {
  // No permissions needed on Windows
  if (Platform.isWindows) {
    return true;
  }

  if (Platform.isAndroid) {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      if (statuses[Permission.storage]!.isGranted ||
          statuses[Permission.manageExternalStorage]!.isGranted) {
        return true;
      }

      bool isPermanentlyDenied = await Permission.storage.isPermanentlyDenied ||
          await Permission.manageExternalStorage.isPermanentlyDenied;

      if (isPermanentlyDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'يرجى تفعيل صلاحيات التخزين من إعدادات التطبيق',
                style: const TextStyle(),
              ),
              action: SnackBarAction(
                label: 'الإعدادات',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  return true;
}
