import 'package:flutter/material.dart';

class EnhancedPrivacyPolicyScreen extends StatelessWidget {
  final bool showAppBar;

  const EnhancedPrivacyPolicyScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary,
            scheme.surface,
          ],
          stops: const [0.0, 0.1],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(context),
            const SizedBox(height: 20),

            // مقدمة
            _buildEnhancedSection(
              icon: Icons.info_outline,
              title: 'مقدمة',
              content: '''
نحن في تجارتي نحترم خصوصيتك ونلتزم بحماية معلوماتك. هذا التطبيق يستخدم قاعدة بيانات محلية تماماً ولا نجمع أي معلومات شخصية عن المستخدمين. **مهم جداً:** جميع بياناتك محفوظة محلياً على جهازك فقط ولا يتم إرسالها إلى أي خادم خارجي. آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

تجارتي هو تطبيق محلي مصمم لمساعدتك في إدارة عملك اليومي بكفاءة وأمان. جميع البيانات محفوظة محلياً على جهازك ولا يتم مشاركتها مع أي طرف ثالث.
''',
            ),
            const SizedBox(height: 20),

            // المعلومات التي نجمعها
            _buildEnhancedSection(
              icon: Icons.data_usage,
              title: 'المعلومات التي نجمعها',
              content: '''
نحن لا نجمع أي معلومات شخصية عن المستخدمين. جميع البيانات محفوظة محلياً على جهازك فقط. التطبيق يعمل بالكامل دون اتصال بالإنترنت ولا يتطلب أي معلومات شخصية للعمل. البيانات المحفوظة محلياً تشمل: معلومات المنتجات والعملاء والمبيعات والموردين والمصاريف. جميع هذه البيانات محفوظة في قاعدة بيانات محلية على جهازك ولا يتم إرسالها إلى أي خادم خارجي.
''',
            ),
            const SizedBox(height: 20),

            // كيفية استخدام المعلومات
            _buildEnhancedSection(
              icon: Icons.security,
              title: 'كيفية استخدام المعلومات',
              content: '''
نظراً لأننا لا نجمع أي معلومات شخصية، فإن جميع البيانات محفوظة محلياً على جهازك فقط. نحن لا نصل إلى بياناتك ولا نشاركها مع أي طرف ثالث. التطبيق يعمل بالكامل محلياً دون الحاجة إلى اتصال بالإنترنت. يمكنك استخدام التطبيق بثقة تامة مع العلم أن جميع بياناتك آمنة ومحفوظة محلياً على جهازك.
''',
            ),
            const SizedBox(height: 20),

            // حماية البيانات
            _buildEnhancedSection(
              icon: Icons.lock,
              title: 'حماية البيانات',
              content: '''
جميع البيانات محفوظة محلياً على جهازك باستخدام تقنيات التشفير المتقدمة. نحن لا نصل إلى بياناتك ولا نشاركها مع أي طرف ثالث. التطبيق يعمل بالكامل محلياً دون الحاجة إلى اتصال بالإنترنت. يمكنك استخدام التطبيق بثقة تامة مع العلم أن جميع بياناتك آمنة ومحفوظة محلياً على جهازك.
''',
            ),
            const SizedBox(height: 20),

            // الأذونات المستخدمة
            _buildEnhancedSection(
              icon: Icons.perm_device_information,
              title: 'الأذونات المستخدمة ولماذا',
              content: '''
يطلب التطبيق الأذونات التالية من نظام التشغيل للوظائف الأساسية فقط:

📱 **أذونات التخزين والملفات:**
• قراءة وكتابة الملفات: لحفظ قاعدة البيانات والنسخ الاحتياطية
• الوصول للتخزين الخارجي: لتصدير التقارير وملفات PDF
• إدارة الملفات: لتنظيم النسخ الاحتياطية والاستعادة

🖨️ **أذونات الطباعة والبلوتوث:**
• البلوتوث: للطباعة على الطابعات اللاسلكية
• مشاركة الملفات: لإرسال ملفات PDF للطابعة أو التطبيقات الأخرى
• الوصول للطابعات: لطباعة الفواتير والتقارير

📷 **أذونات الكاميرا والصور (اختيارية):**
• الكاميرا: لالتقاط صور المنتجات (عند الحاجة)
• مكتبة الصور: لاختيار صور المنتجات من المعرض

🌐 **أذونات الشبكة:**
• الإنترنت: للوصول للموقع الرسمي والدعم الفني فقط
• لا يتم إرسال أي بيانات شخصية عبر الإنترنت

🔒 **مهم جداً:** جميع الأذونات تستخدم فقط للوظائف المطلوبة ولا يتم الوصول لأي معلومات شخصية غير ضرورية. جميع البيانات تبقى محفوظة محلياً على جهازك.''',
            ),
            const SizedBox(height: 20),

            // الاحتفاظ بالبيانات والحذف
            _buildEnhancedSection(
              icon: Icons.delete_outline,
              title: 'الاحتفاظ بالبيانات وحذفها',
              content: '''
جميع بياناتك تبقى على جهازك طالما لم تقم بحذفها. يمكنك في أي وقت:\n\n• إنشاء نسخة احتياطية يدوياً وحفظها خارج الجهاز.\n• استعادة نسخة احتياطية سابقة.\n• حذف البيانات عبر استبدال القاعدة أو إزالة التطبيق (قد يؤدي ذلك لفقدان البيانات إن لم تكن هناك نسخة احتياطية).''',
            ),
            const SizedBox(height: 20),

            // النسخ الاحتياطي والأمان
            _buildEnhancedSection(
              icon: Icons.backup,
              title: 'النسخ الاحتياطي وأمان الملفات',
              content: '''
ملفات النسخ الاحتياطي قد تحتوي بيانات حساسة (مثل معلومات الفواتير والعملاء) لذا ننصح بما يلي:\n\n• حفظ النسخ في موقع آمن ومشفر عند الإمكان.\n• عدم مشاركة الملفات مع أطراف غير مخولّة.\n• اختبار الاستعادة دورياً للتأكد من سلامة النسخ.''',
            ),
            const SizedBox(height: 20),

            // الأمان والخصوصية المتقدمة
            _buildEnhancedSection(
              icon: Icons.security,
              title: 'الأمان والخصوصية المتقدمة',
              content: '''
🔐 **حماية البيانات:**
• تشفير قاعدة البيانات: جميع البيانات محمية بتشفير متقدم
• عدم الوصول للإنترنت: التطبيق يعمل محلياً بالكامل
• حماية الملفات: النسخ الاحتياطية محمية بكلمات مرور

🛡️ **إعدادات الأمان:**
• أذونات محدودة: فقط الأذونات الضرورية للوظائف الأساسية
• عدم التتبع: لا يتم تتبع أي نشاط أو بيانات
• عدم المشاركة: لا يتم مشاركة أي بيانات مع أطراف ثالثة

🔒 **الخصوصية:**
• بيانات محلية: جميع البيانات محفوظة على جهازك فقط
• عدم الإرسال: لا يتم إرسال أي معلومات للخوادم الخارجية
• التحكم الكامل: أنت تتحكم في جميع بياناتك''',
            ),
            const SizedBox(height: 20),

            // عدم التتبع وعدم استخدام طرف ثالث
            _buildEnhancedSection(
              icon: Icons.shield_moon,
              title: 'عدم التتبع وعدم استخدام خدمات طرف ثالث',
              content: '''
لا نستخدم أي تحليلات، تتبّع، أو خدمات طرف ثالث تجمع بيانات استخدامك. لا يتم إرسال أي معلومات أو مقاييس استخدام إلى خوادم خارجية. كل ما يجري يحدث محلياً على جهازك فقط.''',
            ),
            const SizedBox(height: 20),

            // الأذونات حسب المنصة
            _buildEnhancedSection(
              icon: Icons.phone_android,
              title: 'الأذونات حسب المنصة',
              content: '''
📱 **Android:**
• التخزين: قراءة/كتابة الملفات للنسخ الاحتياطية
• البلوتوث: للطباعة على الطابعات اللاسلكية
• الكاميرا: لالتقاط صور المنتجات (اختياري)
• الإنترنت: للوصول للموقع الرسمي فقط

🍎 **iOS:**
• التخزين: الوصول للملفات للنسخ الاحتياطية
• الكاميرا: لالتقاط صور المنتجات (اختياري)
• مكتبة الصور: لاختيار صور المنتجات (اختياري)
• البلوتوث: للطباعة على الطابعات اللاسلكية

🌐 **Web:**
• التخزين المحلي: لحفظ البيانات في المتصفح
• الطباعة: لطباعة الفواتير والتقارير
• مشاركة الملفات: لتصدير ملفات PDF

🔒 **جميع المنصات:** لا يتم الوصول لأي أذونات غير ضرورية، وجميع البيانات تبقى محلية.''',
            ),
            const SizedBox(height: 20),

            // حقوقك
            _buildEnhancedSection(
              icon: Icons.person,
              title: 'حقوقك',
              content: '''
نظراً لأننا لا نجمع أي معلومات شخصية، فإن جميع البيانات محفوظة محلياً على جهازك فقط. يمكنك الوصول إلى جميع بياناتك في أي وقت من خلال التطبيق. يمكنك أيضاً إنشاء نسخ احتياطية من بياناتك وحذفها في أي وقت. جميع البيانات محفوظة محلياً على جهازك ولا يتم إرسالها إلى أي خادم خارجي.
''',
            ),
            const SizedBox(height: 20),

            // معلومات إضافية
            _buildInfoCard(context),
            const SizedBox(height: 20),

            // أزرار العمل
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            title: const Text(
              'سياسة الخصوصية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
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
              Icons.privacy_tip,
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
                  'سياسة الخصوصية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تجارتي',
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

  Widget _buildEnhancedSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: scheme.primary.withOpacity(0.2),
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
                    color: scheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
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
          ],
        ),
      );
    });
  }

  Widget _buildInfoCard(BuildContext context) {
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
                  Icons.info,
                  color: scheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات إضافية',
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
            'هذا التطبيق يعمل بالكامل محلياً ولا يتطلب اتصال بالإنترنت. جميع البيانات محفوظة محلياً على جهازك ولا يتم إرسالها إلى أي خادم خارجي. يمكنك استخدام التطبيق بثقة تامة مع العلم أن جميع بياناتك آمنة ومحفوظة محلياً على جهازك.',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedTermsConditionsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.description),
            label: const Text('شروط الاستخدام'),
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

// شاشة شروط الاستخدام المحسنة
class EnhancedTermsConditionsScreen extends StatelessWidget {
  final bool showAppBar;

  const EnhancedTermsConditionsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.primary,
            scheme.surface,
          ],
          stops: const [0.0, 0.1],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(context),
            const SizedBox(height: 20),

            // مقدمة
            _buildEnhancedSection(
              icon: Icons.info_outline,
              title: 'مقدمة',
              content: '''
مرحباً بك في تجارتي. باستخدامك لهذا التطبيق، فإنك توافق على الالتزام بشروط الاستخدام هذه. **مهم:** هذا التطبيق يعمل محلياً بالكامل ولا يتطلب اتصال بالإنترنت. آخر تحديث: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

تجارتي هو تطبيق محلي مصمم لمساعدتك في إدارة عملك اليومي بكفاءة وأمان. جميع البيانات محفوظة محلياً على جهازك ولا يتم مشاركتها مع أي طرف ثالث.
''',
            ),
            const SizedBox(height: 20),

            // القبول بالشروط
            _buildEnhancedSection(
              icon: Icons.check_circle_outline,
              title: 'القبول بالشروط',
              content: '''
باستخدامك لهذا التطبيق، فإنك تؤكد أنك قد قرأت وفهمت هذه الشروط وتوافق على الالتزام بها. إذا كنت لا توافق على أي من هذه الشروط، فيرجى عدم استخدام التطبيق. هذه الشروط تنطبق على جميع المستخدمين والزوار الذين يصلون إلى التطبيق أو يستخدمونه.
''',
            ),
            const SizedBox(height: 20),

            // الأذونات والاستخدام
            _buildEnhancedSection(
              icon: Icons.security,
              title: 'الأذونات والاستخدام',
              content: '''
🔐 **الأذونات المطلوبة:**
• التخزين: لحفظ قاعدة البيانات والنسخ الاحتياطية
• الطباعة: لطباعة الفواتير والتقارير
• الكاميرا: لالتقاط صور المنتجات (اختياري)
• البلوتوث: للطباعة على الطابعات اللاسلكية

📱 **الاستخدام المسموح:**
• إدارة المبيعات والمشتريات
• إدارة العملاء والموردين
• إنشاء التقارير والفواتير
• النسخ الاحتياطي والاستعادة

🚫 **الاستخدام المحظور:**
• أي نشاط غير قانوني أو مخالف للقوانين
• محاولة اختراق أو تعديل التطبيق
• استخدام التطبيق لأغراض ضارة أو تهديدية''',
            ),
            const SizedBox(height: 20),

            // الاستخدام المسموح
            _buildEnhancedSection(
              icon: Icons.verified_user,
              title: 'الاستخدام المسموح',
              content: '''
يُسمح لك باستخدام هذا التطبيق للأغراض التجارية والشخصية المشروعة فقط. يجب عليك عدم استخدام التطبيق لأي غرض غير قانوني أو محظور. أنت مسؤول عن جميع الأنشطة التي تحدث تحت حسابك. يجب عليك الحفاظ على سرية كلمة المرور الخاصة بك وعدم مشاركتها مع الآخرين.
''',
            ),
            const SizedBox(height: 20),

            // القيود والمنع
            _buildEnhancedSection(
              icon: Icons.block,
              title: 'القيود والمنع',
              content: '''
يُمنع منعاً باتاً استخدام التطبيق لأي من الأغراض التالية: انتهاك أي قانون أو لائحة محلية أو وطنية أو دولية، إرسال أو نقل أي محتوى غير قانوني أو ضار أو مهدد أو مسيء أو تشهيري أو فاحش أو غير أخلاقي، التدخل في عمل التطبيق أو الخوادم أو الشبكات المتصلة بالتطبيق، محاولة الوصول غير المصرح به إلى أي جزء من التطبيق أو الأنظمة المتصلة به.
''',
            ),
            const SizedBox(height: 20),

            // الملكية الفكرية
            _buildEnhancedSection(
              icon: Icons.copyright,
              title: 'الملكية الفكرية',
              content: '''
جميع المحتويات الموجودة في هذا التطبيق، بما في ذلك النصوص والرسوم والصور والبرامج والكود المصدري، محمية بحقوق الطبع والنشر والعلامات التجارية وغيرها من حقوق الملكية الفكرية. لا يجوز لك نسخ أو تعديل أو توزيع أو بيع أو تأجير أي جزء من التطبيق دون الحصول على إذن كتابي صريح منا.
''',
            ),
            const SizedBox(height: 20),

            // إخلاء المسؤولية
            _buildEnhancedSection(
              icon: Icons.warning_amber,
              title: 'إخلاء المسؤولية',
              content: '''
يتم توفير هذا التطبيق "كما هو" دون أي ضمانات من أي نوع، صريحة أو ضمنية. نحن لا نضمن أن التطبيق سيعمل دون انقطاع أو خالي من الأخطاء. نحن غير مسؤولين عن أي أضرار مباشرة أو غير مباشرة قد تنتج عن استخدام التطبيق. المستخدم يتحمل المسؤولية الكاملة عن استخدام التطبيق والبيانات المدخلة فيه.
''',
            ),
            const SizedBox(height: 20),

            // التعديلات على الشروط
            _buildEnhancedSection(
              icon: Icons.edit,
              title: 'التعديلات على الشروط',
              content: '''
نحتفظ بالحق في تعديل هذه الشروط في أي وقت دون إشعار مسبق. التعديلات ستصبح فعالة فور نشرها في التطبيق. استمرارك في استخدام التطبيق بعد التعديلات يعني موافقتك على الشروط الجديدة. ننصحك بمراجعة هذه الشروط بانتظام للاطلاع على أي تحديثات.
''',
            ),
            const SizedBox(height: 20),

            // القانون الحاكم
            _buildEnhancedSection(
              icon: Icons.gavel,
              title: 'القانون الحاكم',
              content: '''
هذه الشروط تحكمها وتفسرها قوانين جمهورية العراق. أي نزاع ينشأ من أو يتعلق بهذه الشروط سيخضع للاختصاص الحصري للمحاكم العراقية. في حالة وجود أي نزاع، سنحاول حله ودياً أولاً قبل اللجوء إلى القضاء.
''',
            ),
            const SizedBox(height: 20),

            // سياسة الترخيص
            _buildEnhancedSection(
              icon: Icons.vpn_key,
              title: 'سياسة الترخيص',
              content: '''
قد يتطلب التطبيق مفتاح ترخيص لاستخدام بعض الميزات أو لإزالة القيود. أنت مسؤول عن حفظ المفتاح بسرية وعدم مشاركته. يحق لنا إبطال المفاتيح التي يتم إساءة استخدامها. في حال انتهاء الترخيص، قد تتأثر بعض الوظائف إلى حين التجديد.''',
            ),
            const SizedBox(height: 20),

            // الدعم والتحديثات
            _buildEnhancedSection(
              icon: Icons.support_agent,
              title: 'الدعم الفني والتحديثات',
              content: '''
نوفر قنوات تواصل للدعم عبر البريد/الواتساب كما هو مذكور في الإعدادات. نسعى للرد خلال إطار زمني معقول، دون التزام زمني محدد. التحديثات قد تحتوي تحسينات أو إصلاحات وقد تتطلب إجراءات نسخ احتياطي مسبقة. استمرار استخدامك يعني قبول التغييرات.''',
            ),
            const SizedBox(height: 20),

            // سياسة الاسترجاع/المدفوعات
            _buildEnhancedSection(
              icon: Icons.receipt_long,
              title: 'سياسة المدفوعات والاسترجاع',
              content: '''
لا يتضمن التطبيق مدفوعات داخلية. في حال وجود اتفاقيات شراء أو اشتراك خارج التطبيق، تطبق شروط المزود/البائع الخاصّة، وقد لا يتوفر استرجاع من داخل التطبيق. يُرجى مراجعة شروط العرض الذي حصلت بموجبه على الترخيص.''',
            ),
            const SizedBox(height: 20),

            // توضيح حدود المسؤولية الموسع
            _buildEnhancedSection(
              icon: Icons.warning,
              title: 'حدود المسؤولية (توضيح)',
              content: '''
نوصي بأخذ نسخ احتياطية دورية. نحن غير مسؤولين عن أي فقدان بيانات ناتج عن سوء الاستخدام، الأعطال، أو عدم القيام بالنسخ الاحتياطي. استخدامك للتطبيق يعني موافقتك على تحمل المسؤولية عن إدارة بياناتك ونسخك الاحتياطية.''',
            ),
            const SizedBox(height: 20),

            // معلومات الاتصال
            _buildEnhancedSection(
              icon: Icons.contact_support,
              title: 'معلومات الاتصال',
              content: '''
إذا كان لديك أي أسئلة حول هذه الشروط، يرجى التواصل معنا عبر: البريد الإلكتروني: barzan.dawood.dev@gmail.com العنوان: نينوى - سنجار، العراق. سنكون سعداء لمساعدتك والإجابة على استفساراتك في أقرب وقت ممكن.
''',
            ),
            const SizedBox(height: 20),

            // أزرار العمل
            _buildActionButtons(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            title: const Text(
              'شروط الاستخدام',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
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
              Icons.description,
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
                  'شروط الاستخدام',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تجارتي',
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

  Widget _buildEnhancedSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: scheme.primary.withOpacity(0.2),
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
                    color: scheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
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
          ],
        ),
      );
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedPrivacyPolicyScreen(),
                ),
              );
            },
            icon: const Icon(Icons.privacy_tip),
            label: const Text('سياسة الخصوصية'),
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
