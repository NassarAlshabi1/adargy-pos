import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/dark_mode_utils.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {});
    }
  }

  InputDecoration _pill(BuildContext context, String hint, IconData icon) {
    return DarkModeUtils.createPillInputDecoration(
      context,
      hintText: hint,
      prefixIcon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              FilledButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة قسم')),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: _pill(context, 'بحث عن قسم', Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getCategories(query: _query),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final items = snap.data!;
                  if (items.isEmpty)
                    return const Center(child: Text('لا توجد أقسام'));
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 3.2,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final c = items[index];
                          final color = Color((c['color'] as int?) ??
                              0xFF1976D2); // Professional Blue
                          final iconData = IconData(
                              (c['icon'] as int?) ?? Icons.folder.codePoint,
                              fontFamily: 'MaterialIcons');
                          return _FancyCategoryCard(
                            name: c['name']?.toString() ?? '',
                            color: color,
                            iconData: iconData,
                            onTap: () async {
                              await _showCategoryProductsDialog(
                                context,
                                c['id'] as int,
                                c['name']?.toString() ?? 'القسم',
                                color,
                                _refresh, // callback لتحديث الصفحة
                              );
                            },
                            onEdit: () => _openEditor(category: c),
                            onDelete: () => _delete(c['id'] as int),
                            countFuture: db.database.rawQuery(
                                'SELECT COUNT(*) c FROM products WHERE category_id = ?',
                                [c['id']]).then((r) => (r.first['c'] as int)),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final db = context.read<DatabaseService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف القسم'),
        content: const Text('هل تريد حذف هذا القسم؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) {
      try {
        final deletedRows = await db.deleteCategory(id);
        if (!mounted) {
          return;
        }

        if (deletedRows > 0) {
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف القسم بنجاح'),
              backgroundColor: Color(0xFF059669), // Professional Green
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لم يتم العثور على القسم أو حدث خطأ في الحذف'),
              backgroundColor: Color(0xFFF59E0B), // Professional Orange
            ),
          );
        }
      } catch (e) {
        if (!mounted) {
          return;
        }
        String errorMessage = 'خطأ في حذف القسم';
        if (e.toString().contains('FOREIGN KEY constraint failed')) {
          errorMessage = 'لا يمكن حذف القسم لأنه يحتوي على منتجات';
        } else if (e.toString().contains('database is locked')) {
          errorMessage = 'قاعدة البيانات قيد الاستخدام، حاول مرة أخرى';
        } else {
          errorMessage = 'خطأ في حذف القسم: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Color(0xFFDC2626), // Professional Red
          ),
        );
      }
    }
  }

  Future<void> _openEditor({Map<String, Object?>? category}) async {
    final db = context.read<DatabaseService>();
    final formKey = GlobalKey<FormState>();
    final name =
        TextEditingController(text: category?['name']?.toString() ?? '');
    int selectedColor =
        (category?['color'] as int?) ?? 0xFF1976D2; // Professional Blue
    int selectedIcon = (category?['icon'] as int?) ?? Icons.folder.codePoint;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 600,
                minWidth: 400,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(category == null ? 'إضافة قسم' : 'تعديل قسم',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            IconButton(
                                onPressed: () => Navigator.pop(context, false),
                                icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: name,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration:
                              _pill(context, 'اسم القسم', Icons.category),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 16),

                        // تخطيط أفقي للأيقونات والألوان
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // قسم الأيقونات
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('الأيقونة',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: DarkModeUtils.getBorderColor(
                                              context)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            for (final ic in _iconOptions)
                                              GestureDetector(
                                                onTap: () => setStateDialog(
                                                    () => selectedIcon =
                                                        ic.codePoint),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: selectedIcon ==
                                                            ic.codePoint
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : DarkModeUtils
                                                                .getSurfaceColor(
                                                                    context)
                                                            .withOpacity(0.5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: selectedIcon ==
                                                              ic.codePoint
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                          : Colors
                                                              .grey.shade300,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    ic,
                                                    color: selectedIcon ==
                                                            ic.codePoint
                                                        ? Colors.white
                                                        : Colors.grey.shade600,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // قسم الألوان
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('اللون',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: DarkModeUtils.getBorderColor(
                                              context)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (final col in _colorOptions)
                                              GestureDetector(
                                                onTap: () => setStateDialog(
                                                    () => selectedColor =
                                                        col.value),
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: col,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: selectedColor ==
                                                              col.value
                                                          ? Colors.black
                                                          : Colors
                                                              .grey.shade300,
                                                      width: selectedColor ==
                                                              col.value
                                                          ? 3
                                                          : 1,
                                                    ),
                                                  ),
                                                  child: selectedColor ==
                                                          col.value
                                                      ? const Icon(Icons.check,
                                                          color: Colors.white,
                                                          size: 16)
                                                      : null,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                Navigator.pop(context, true);
                              },
                              child: const Text('حفظ'),
                            ),
                            const Spacer(),
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('إلغاء')),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
    if (ok == true) {
      await db.upsertCategory({
        'name': name.text.trim(),
        'icon': selectedIcon,
        'color': selectedColor
      }, id: category?['id'] as int?);
      if (!mounted) {
        return;
      }
      _refresh();
    }
  }
}

class _FancyCategoryCard extends StatefulWidget {
  const _FancyCategoryCard({
    required this.name,
    required this.color,
    required this.iconData,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.countFuture,
  });

  final String name;
  final Color color;
  final IconData iconData;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<int> countFuture;

  @override
  State<_FancyCategoryCard> createState() => _FancyCategoryCardState();
}

class _FancyCategoryCardState extends State<_FancyCategoryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [widget.color.withOpacity(0.9), widget.color.withOpacity(0.6)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Stack(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Icon(widget.iconData,
                          size: 84, color: Colors.white.withOpacity(0.12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Color(0xFFFFFFFF), // Professional White
                            child: Icon(widget.iconData,
                                size: 22, color: widget.color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                FutureBuilder<int>(
                                  future: widget.countFuture,
                                  builder: (context, snap) {
                                    final count = snap.data ?? 0;
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ui.ImageFilter.blur(
                                            sigmaX: 6, sigmaY: 6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                DarkModeUtils.getBackdropColor(
                                                    context),
                                            border: Border.all(
                                                color: DarkModeUtils
                                                    .getBackdropBorderColor(
                                                        context)),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text('عدد المنتجات: $count',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Row(children: [
                _actionCircle(
                    icon: Icons.edit,
                    tooltip: 'تعديل',
                    color: Colors.white,
                    iconColor: widget.color,
                    onTap: widget.onEdit),
                const SizedBox(width: 6),
                _actionCircle(
                    icon: Icons.delete_outline,
                    tooltip: 'حذف',
                    color: Colors.white,
                    iconColor: Colors.red.shade700,
                    onTap: widget.onDelete),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCircle(
      {required IconData icon,
      required String tooltip,
      required Color color,
      required Color iconColor,
      required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ),
    );
  }
}

const _iconOptions = <IconData>[
// أجهزة الهاتف والاتصالات
  Icons.phone_iphone,
  Icons.phone_android,
  Icons.devices_other,
  Icons.watch,
  Icons.headphones,
  Icons.speaker,

// أجهزة الكمبيوتر والتكنولوجيا
  Icons.laptop,
  Icons.computer,
  Icons.desktop_windows,
  Icons.monitor,
  Icons.keyboard,
  Icons.mouse,
  Icons.memory,
  Icons.storage,
  Icons.usb,
  Icons.cable,

// الشبكات والاتصالات
  Icons.router,
  Icons.wifi,
  Icons.lan,
  Icons.network_check,
  Icons.settings_input_antenna,
  Icons.satellite_alt,
  Icons.satellite,

// الأجهزة المنزلية
  Icons.tv,
  Icons.radio,
  Icons.camera_alt,
  Icons.videocam,
  Icons.mic,
  Icons.airplay,

// الكهرباء والإضاءة
  Icons.electrical_services,
  Icons.lightbulb,
  Icons.power,
  Icons.bolt,
  Icons.flash_on,
  Icons.battery_charging_full,

// الأجهزة المنزلية الأخرى
  Icons.kitchen,
  Icons.local_laundry_service,
  Icons.ac_unit,
  Icons.air,
  Icons.water_drop,
  Icons.thermostat,

// الأدوات والمعدات
  Icons.build,
  Icons.handyman,
  Icons.settings,
  Icons.tune,
  Icons.precision_manufacturing,
  Icons.engineering,

// الألعاب والترفيه
  Icons.sports_esports,
  Icons.gamepad,
  Icons.toys,
  Icons.music_note,
  Icons.movie,

// الأمن والمراقبة
  Icons.security,
  Icons.camera_indoor,
  Icons.camera_outdoor,
  Icons.lock,
  Icons.fingerprint,

// النقل والمركبات
  Icons.directions_car,
  Icons.motorcycle,
  Icons.bike_scooter,
  Icons.flight,
  Icons.train,

// الصحة والطب
  Icons.medical_services,
  Icons.favorite,
  Icons.local_hospital,
  Icons.healing,
  Icons.medication,

// الرياضة واللياقة
  Icons.sports_soccer,
  Icons.sports_basketball,
  Icons.sports_tennis,
  Icons.fitness_center,
  Icons.pool,

// الطعام والشراب
  Icons.restaurant,
  Icons.coffee,
  Icons.local_pizza,
  Icons.cake,
  Icons.wine_bar,

// الملابس والأزياء
  Icons.checkroom,
  Icons.diamond,
  Icons.watch,
  Icons.visibility,
  Icons.accessibility_new,

// الكتب والتعليم
  Icons.book,
  Icons.school,
  Icons.library_books,
  Icons.edit,
  Icons.calculate,

// المكتب والأعمال
  Icons.business,
  Icons.work,
  Icons.folder,
  Icons.description,
  Icons.print,

// السفر والسياحة
  Icons.flight,
  Icons.hotel,
  Icons.beach_access,
  Icons.landscape,
  Icons.map,

// الحيوانات الأليفة
  Icons.pets,
  Icons.cruelty_free,
  Icons.grass,
  Icons.park,

// البستنة والزراعة
  Icons.local_florist,
  Icons.eco,
  Icons.agriculture,
  Icons.water_drop,
  Icons.sunny,
];

const _colorOptions = <Color>[
// ألوان احترافية لنظام المبيعات
  Color(0xFF1976D2), // أزرق احترافي
  Color(0xFF059669), // أخضر احترافي
  Color(0xFFF59E0B), // برتقالي احترافي
  Color(0xFF7C3AED), // بنفسجي احترافي
  Color(0xFF0891B2), // تركوازي احترافي
  Color(0xFF92400E), // بني احترافي
  Color(0xFF475569), // رمادي أزرق احترافي
  Color(0xFFEAB308), // أصفر احترافي

// ألوان إضافية احترافية
  Color(0xFFDC2626), // أحمر احترافي
  Color(0xFF8B5CF6), // بنفسجي فاتح احترافي
  Color(0xFF6B21A8), // بنفسجي داكن احترافي
  Color(0xFF3B82F6), // نيلي احترافي
  Color(0xFF0EA5E9), // أزرق فاتح احترافي
  Color(0xFF06B6D4), // سماوي احترافي
  Color(0xFF10B981), // أخضر داكن احترافي
  Color(0xFF22C55E), // أخضر فاتح احترافي
  Color(0xFF84CC16), // أخضر مصفر احترافي
  Color(0xFFA3E635), // أصفر أخضر احترافي
  Color(0xFFFDE047), // أصفر ذهبي احترافي
  Color(0xFFF59E0B), // عنبر احترافي
  Color(0xFFF97316), // برتقالي داكن احترافي
  Color(0xFFEF4444), // أحمر برتقالي احترافي
  Color(0xFFA16207), // بني فاتح احترافي
  Color(0xFF64748B), // رمادي أزرق داكن احترافي
  Color(0xFF94A3B8), // رمادي احترافي
  Color(0xFF374151), // رمادي داكن احترافي
];

Future<void> _showCategoryProductsDialog(
  BuildContext context,
  int categoryId,
  String categoryName,
  Color categoryColor,
  VoidCallback onProductAdded,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 800,
          minWidth: 900,
        ),
        child: CategoryProductsScreen(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          onProductAdded: () {
            // إغلاق الحوار مع إشارة إلى إضافة منتج
            Navigator.of(context).pop(true);
          },
        ),
      ),
    ),
  );

  // إذا تم إضافة منتج، قم بتحديث الصفحة
  if (result == true && context.mounted) {
    onProductAdded();
  }
}
