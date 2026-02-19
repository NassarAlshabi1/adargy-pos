import 'package:flutter/material.dart';

class AppUsageGuideScreen extends StatefulWidget {
  final bool showAppBar;

  const AppUsageGuideScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<AppUsageGuideScreen> createState() => _AppUsageGuideScreenState();
}

class _AppUsageGuideScreenState extends State<AppUsageGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, GlobalKey> _sectionKeys = {};
  late List<_GuideSectionData> _allSections;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _allSections = [
      _GuideSectionData(
        icon: Icons.info_outline,
        title: 'مرحباً بك في تجارتي',
        content:
            'نظام شامل لإدارة المتاجر والمكاتب. واجهة عربية بسيطة وسهلة الاستخدام.\n\nالمميزات الرئيسية:\n• إدارة المنتجات والمخزون والأقسام\n• تسجيل المبيعات (نقد/دين/تقسيط)\n• إدارة العملاء والموردين\n• المصروفات والمرتجعات والديون\n• تقارير وتحليلات شاملة\n• إدارة المستخدمين والصلاحيات\n• سجل الأحداث وسلة المحذوفات\n• نسخ احتياطية آمنة',
      ),
      _GuideSectionData(
        icon: Icons.play_arrow,
        title: 'البدء السريع',
        content:
            'الخطوة 1: إعداد المتجر\n• الإعدادات > معلومات المتجر\n• أدخل اسم المتجر ورقم الهاتف والعنوان\n• احفظ\n\nالخطوة 2: إضافة الأقسام والمنتجات\n• اذهب إلى "الأقسام" وأضف الأقسام\n• اذهب إلى "المنتجات" وأضف المنتجات مع تحديد القسم\n• أدخل: الاسم، سعر البيع، الكمية، الوصف\n\nالخطوة 3: أول عملية بيع\n• اذهب إلى "المبيعات"\n• اختر المنتجات والكميات\n• اختر نوع البيع: نقد / دين / تقسيط\n• احفظ واطبع الفاتورة',
      ),
      _GuideSectionData(
        icon: Icons.category,
        title: 'إدارة الأقسام',
        content:
            'تنظيم المنتجات في أقسام:\n• اذهب إلى "الأقسام"\n• اضغط "إضافة قسم جديد"\n• أدخل اسم القسم والوصف\n• احفظ\n\nيمكنك تصفية المنتجات حسب القسم من صفحة المنتجات',
      ),
      _GuideSectionData(
        icon: Icons.inventory_2,
        title: 'إدارة المنتجات والمخزون',
        content:
            'إضافة منتج:\n• المنتجات > إضافة منتج جديد\n• أدخل: الاسم، سعر البيع، الكمية، الوصف، القسم\n• احفظ\n\nتعديل منتج:\n• اختر المنتج من القائمة\n• عدّل المعلومات واحفظ\n\nإدارة المخزون:\n• راقب الكميات من صفحة "المخزون"\n• يتم تحديث المخزون تلقائياً بعد المبيعات والمرتجعات',
      ),
      _GuideSectionData(
        icon: Icons.point_of_sale,
        title: 'تسجيل المبيعات',
        content:
            'عملية بيع جديدة:\n• اذهب إلى "المبيعات"\n• اختر المنتجات وأدخل الكميات\n• اختر نوع البيع:\n  - نقد: دفع فوري\n  - دين: يُسجل المتبقي على العميل\n  - تقسيط: حدد الدفعة الأولى والمتبقي\n• احفظ واطبع الفاتورة\n\nتاريخ المبيعات:\n• من "تاريخ المبيعات" يمكنك:\n  - عرض جميع المبيعات\n  - البحث والتصفية\n  - طباعة الفواتير السابقة',
      ),
      _GuideSectionData(
        icon: Icons.people,
        title: 'إدارة العملاء والموردين',
        content:
            'العملاء:\n• اذهب إلى "العملاء" > إضافة عميل\n• أدخل: الاسم، الهاتف، العنوان\n• يمكنك متابعة الديون والسداد من صفحة العميل\n\nالموردون:\n• اذهب إلى "الموردون" > إضافة مورد\n• أدخل: الاسم، الهاتف، العنوان\n• راقب المستحقات الدائنة',
      ),
      _GuideSectionData(
        icon: Icons.receipt_long,
        title: 'المصروفات',
        content:
            'تسجيل المصروفات:\n• اذهب إلى "المصروفات"\n• اضغط "إضافة مصروف"\n• أدخل: العنوان، المبلغ، الفئة، التاريخ، الوصف\n• احفظ\n\nيمكنك:\n• تصفية المصروفات حسب الفئة والتاريخ\n• تعديل أو حذف المصروفات\n• عرض إحصائيات المصروفات',
      ),
      _GuideSectionData(
        icon: Icons.undo,
        title: 'المرتجعات',
        content:
            'تسجيل مرتجع:\n• اذهب إلى "المرتجعات"\n• اضغط "إضافة مرتجع"\n• اختر الفاتورة الأصلية\n• اختر المنتجات المراد إرجاعها والكميات\n• احفظ\n\nيتم تحديث المخزون تلقائياً عند إرجاع المنتجات',
      ),
      _GuideSectionData(
        icon: Icons.account_balance_wallet,
        title: 'إدارة الديون',
        content:
            'متابعة الديون:\n• اذهب إلى "الديون"\n• عرض جميع الديون المستحقة\n• تصفية حسب العميل أو التاريخ\n• تسجيل سداد من صفحة العميل\n\nالديون تُسجل تلقائياً عند:\n• بيع بالدين\n• بيع بالتقسيط',
      ),
      _GuideSectionData(
        icon: Icons.analytics,
        title: 'التقارير والتحليلات',
        content:
            'التقارير الموحدة:\n• اذهب إلى "التقارير الموحدة"\n• اختر نوع التقرير: مبيعات، مصروفات، مخزون، عملاء\n• حدد الفترة الزمنية\n• اعرض التقرير\n\nالتحليلات:\n• اذهب إلى "التحليلات"\n• عرض إحصائيات شاملة:\n  - إجمالي المبيعات والمصروفات\n  - أفضل المنتجات مبيعاً\n  - تحليل الأرباح\n  - إحصائيات العملاء',
      ),
      _GuideSectionData(
        icon: Icons.history,
        title: 'سجل الأحداث',
        content:
            'متابعة جميع العمليات:\n• اذهب إلى "سجل الأحداث"\n• عرض جميع الأحداث: تسجيل دخول، إضافة، تعديل، حذف\n• تصفية حسب نوع الحدث أو المستخدم\n• البحث في السجل\n\nيساعدك على:\n• تتبع جميع التغييرات\n• مراجعة العمليات\n• الأمان والشفافية',
      ),
      _GuideSectionData(
        icon: Icons.delete_outline,
        title: 'سلة المحذوفات',
        content:
            'استعادة العناصر المحذوفة:\n• اذهب إلى "سلة المحذوفات"\n• عرض جميع العناصر المحذوفة\n• اختر العنصر واضغط "استعادة"\n• يمكنك حذف نهائي للعناصر\n\nملاحظة: بعض العناصر قد لا تكون قابلة للاستعادة',
      ),
      _GuideSectionData(
        icon: Icons.people_outline,
        title: 'إدارة المستخدمين',
        content:
            'إضافة مستخدم جديد:\n• اذهب إلى "إدارة المستخدمين"\n• اضغط "إضافة مستخدم"\n• أدخل: الاسم، الرمز، كلمة المرور، الدور\n• حدد الصلاحيات المطلوبة\n• احفظ\n\nإدارة الصلاحيات:\n• يمكنك تحديد صلاحيات لكل مستخدم:\n  - إدارة المبيعات\n  - إدارة المنتجات\n  - إدارة العملاء\n  - عرض التقارير\n  - إدارة المستخدمين\n  - الإعدادات',
      ),
      _GuideSectionData(
        icon: Icons.backup,
        title: 'النسخ الاحتياطية',
        content:
            'إنشاء نسخة احتياطية:\n• الإعدادات > إعدادات قاعدة البيانات\n• اضغط "إنشاء نسخة احتياطية"\n• حدد مكان الحفظ\n\nاستعادة البيانات:\n• من نفس المكان\n• اختر "استعادة البيانات"\n• اختر ملف النسخة الاحتياطية\n• أكد العملية\n\nنصيحة: أنشئ نسخاً منتظمة لحماية بياناتك',
      ),
      _GuideSectionData(
        icon: Icons.key,
        title: 'نظام الترخيص',
        content:
            'النسخة التجريبية:\n• يمكنك استخدام التطبيق مجاناً لمدة 30 يوم\n• خلال هذه الفترة يمكنك تجربة جميع الميزات\n• راقب الأيام المتبقية من شريط الإشعارات\n\nتفعيل الترخيص:\n• الإعدادات > معلومات التطبيق > فحص الترخيص\n• أدخل مفتاح الترخيص الذي حصلت عليه\n• اضغط "تفعيل الترخيص"\n• الترخيص مرتبط بجهازك فقط\n\nملاحظات مهمة:\n• مفتاح الترخيص مرتبط ببصمة الجهاز\n• لا يمكن نقل الترخيص لجهاز آخر\n• في حالة تغيير الجهاز، تواصل مع الدعم الفني',
      ),
      _GuideSectionData(
        icon: Icons.help_outline,
        title: 'نصائح سريعة',
        content:
            '• استخدم البحث للعثور على المنتجات والعملاء بسرعة\n• نظم المنتجات في أقسام لتسهيل البحث\n• راقب المخزون بانتظام من صفحة "المخزون"\n• استخدم التقارير لمتابعة الأداء\n• أنشئ نسخاً احتياطية منتظمة\n• استخدم سجل الأحداث لمتابعة التغييرات\n• حدد الصلاحيات المناسبة لكل مستخدم',
      ),
    ];
    for (final s in _allSections) {
      _sectionKeys[s.title] = GlobalKey();
    }
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final List<_GuideSectionData> visibleSections = _query.isEmpty
        ? _allSections
        : _allSections.where((s) {
            final q = _query.toLowerCase();
            return s.title.toLowerCase().contains(q) ||
                s.content.toLowerCase().contains(q);
          }).toList();

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.primary, scheme.surface],
          stops: const [0.0, 0.1],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(context),
            const SizedBox(height: 16),

            // Search box
            _buildSearchField(context),
            const SizedBox(height: 12),

            // Table of contents
            _buildTableOfContents(context, visibleSections),
            const SizedBox(height: 16),

            // Sections
            ...visibleSections.map((s) {
              return Padding(
                key: _sectionKeys[s.title],
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCollapsibleSection(
                  icon: s.icon,
                  title: s.title,
                  content: s.content,
                ),
              );
            }),

            const SizedBox(height: 8),
            _buildContactCard(context),
            const SizedBox(height: 12),
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            title: const Text(
              'دليل الاستخدام',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: scheme.onPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: content,
        ),
      );
    } else {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }
  }

  Widget _buildHeaderCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.menu_book,
              color: scheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دليل استخدام التطبيق',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تعلم كيفية استخدام تجارتي',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: scheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: scheme.onSurface,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'ابحث داخل الدليل (مثال: المبيعات، التقارير...)',
        prefixIcon: Icon(Icons.search, color: scheme.primary),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon:
                    Icon(Icons.clear, color: scheme.onSurface.withOpacity(0.6)),
              )
            : null,
      ),
    );
  }

  Widget _buildTableOfContents(
      BuildContext context, List<_GuideSectionData> sections) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, color: scheme.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'المحتويات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sections.map((s) {
              return ActionChip(
                avatar: Icon(s.icon, size: 16, color: scheme.onPrimary),
                backgroundColor: scheme.primary,
                label: Text(
                  s.title,
                  style: TextStyle(color: scheme.onPrimary, fontSize: 12),
                ),
                onPressed: () {
                  final key = _sectionKeys[s.title];
                  if (key != null && key.currentContext != null) {
                    Scrollable.ensureVisible(
                      key.currentContext!,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      alignment: 0.1,
                    );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.secondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: scheme.secondary.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.contact_support,
                  color: scheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'هل تحتاج مساعدة إضافية؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'إذا كان لديك أي أسئلة أو تحتاج مساعدة إضافية، لا تتردد في التواصل معنا:\n\n📧 البريد الإلكتروني: barzan.dawood.dev@gmail.com\n📱 الواتساب: 07866744144',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: scheme.secondary,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('فهمت، شكراً'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('إغلاق'),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.primary,
              side: BorderSide(color: scheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideSectionData {
  final IconData icon;
  final String title;
  final String content;

  const _GuideSectionData({
    required this.icon,
    required this.title,
    required this.content,
  });
}
