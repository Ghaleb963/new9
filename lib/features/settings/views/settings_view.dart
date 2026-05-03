import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../../core/utils/encryption_helper.dart';
import '../../../core/database/database_helper.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../properties/providers/property_provider.dart';
import '../../../core/widgets/app_form_widgets.dart';
import '../../../core/theme/app_theme.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _activationController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fbController = TextEditingController();
  final _instaController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _activationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _fbController.dispose();
    _instaController.dispose();
    super.dispose();
  }

  void _initControllers(SettingsState settings) {
    if (!_initialized && !settings.isLoading) {
      _nameController.text = settings.officeName;
      _phoneController.text = settings.officePhone;
      _fbController.text = settings.facebookLink;
      _instaController.text = settings.instagramLink;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _initControllers(settings);

    if (settings.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgPage,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      appBar: AppBar(
        backgroundColor: AppTheme.bgPage,
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.sp16),
        children: [
          const AppSectionTitle(
              title: 'تفعيل التطبيق', icon: Icons.verified_rounded),
          _ActivationCard(
            settings: settings,
            controller: _activationController,
          ),
          const SizedBox(height: AppTheme.sp20),
          const AppSectionTitle(
              title: 'بيانات المكتب', icon: Icons.business_rounded),
          _OfficeDataCard(
            nameCtrl: _nameController,
            phoneCtrl: _phoneController,
            fbCtrl: _fbController,
            instaCtrl: _instaController,
            onSave: () {
              ref.read(settingsProvider.notifier).updateOfficeData(
                    name: _nameController.text,
                    phone: _phoneController.text,
                    fb: _fbController.text,
                    insta: _instaController.text,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم حفظ البيانات')),
              );
            },
          ),
          const SizedBox(height: AppTheme.sp20),
          const AppSectionTitle(
              title: 'النسخ الاحتياطي والأمان', icon: Icons.security_rounded),
          _BackupCard(
            onExport: () => _exportDatabase(context),
            onImport: () => _importDatabase(context),
          ),
          const SizedBox(height: AppTheme.sp20),
          if (settings.isActivated)
            _LogoutButton(
              onTap: () => _showLogoutDialog(context, settings),
            ),
          const SizedBox(height: AppTheme.sp32),
        ],
      ),
    );
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  Future<void> _exportDatabase(BuildContext context) async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      final sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      final ts = DateTime.now()
          .toLocal()
          .toString()
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName = 'realestate_backup_$ts.db';

      // استخدام FilePicker لاختيار مكان الحفظ مباشرة (يعمل على جميع المنصات)
      String? savePath;
      if (Platform.isAndroid || Platform.isIOS) {
        // على الموبايل نستخدم getDirectoryPath ثم ندمج اسم الملف
        final directoryPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'اختر مجلد حفظ النسخة الاحتياطية',
        );
        if (directoryPath != null) {
          savePath = '$directoryPath/$fileName';
        }
      } else {
        // على الديسك توب نستخدم saveFile مباشرة
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية',
          fileName: fileName,
        );
      }

      if (savePath == null) return;

      await sourceFile.copy(savePath);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ تم حفظ النسخة الاحتياطية بنجاح في:\n$savePath'),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل التصدير: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  // ── Import ─────────────────────────────────────────────────────────────────
  Future<void> _importDatabase(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final selectedPath = result.files.single.path!;

    // التحقق من صحة الملف قبل بدء عملية الاستبدال
    final isValid = await DatabaseHelper.instance.isValidDatabase(selectedPath);
    if (!isValid) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('الملف المختار ليس قاعدة بيانات صالحة لهذا التطبيق'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.sp24),
          decoration: BoxDecoration(
            color: AppTheme.bgRaised,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.accentGreen),
              SizedBox(height: AppTheme.sp16),
              Text('جاري الاستيراد...',
                  style: TextStyle(color: AppTheme.textMedium)),
            ],
          ),
        ),
      ),
    );

    try {
      await DatabaseHelper.instance.closeDatabase();
      final dbPath = await DatabaseHelper.instance.getDatabasePath();
      await File(selectedPath).copy(dbPath);
      await ref.read(propertyProvider.notifier).loadProperties();

      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✓ تم الاستيراد وتحديث القائمة'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('فشل الاستيراد: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  // ── Logout Dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context, SettingsState settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text(
          'هل أنت متأكد؟ سيتم إلغاء تفعيل التطبيق وتغيير معرّف الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              final logoutCode =
                  EncryptionHelper.generateLogoutCode(settings.deviceId);
              await ref.read(settingsProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.pop(context);
              _showLogoutCodeDialog(context, logoutCode);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentRed),
            child: const Text('تأكيد الخروج'),
          ),
        ],
      ),
    );
  }

  void _showLogoutCodeDialog(BuildContext context, String logoutCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم الخروج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('كود الخروج الخاص بك:'),
            const SizedBox(height: AppTheme.sp12),
            Container(
              padding: const EdgeInsets.all(AppTheme.sp16),
              decoration: BoxDecoration(
                color: AppTheme.bgRaised,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.borderMedium),
              ),
              child: SelectableText(
                logoutCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppTheme.accentRed,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logoutCode));
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('نسخ وإغلاق'),
          ),
        ],
      ),
    );
  }
}

// ── Activation Card ───────────────────────────────────────────────────────────
class _ActivationCard extends ConsumerWidget {
  final SettingsState settings;
  final TextEditingController controller;

  const _ActivationCard({
    required this.settings,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          // Device code row
          Padding(
            padding: const EdgeInsets.all(AppTheme.sp16),
            child: Row(
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  color: AppTheme.textLow,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.sp12),
                const Text(
                  'رمز الجهاز:',
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: AppTheme.fontSm,
                  ),
                ),
                const SizedBox(width: AppTheme.sp8),
                Expanded(
                  child: Text(
                    settings.userCode,
                    style: const TextStyle(
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTheme.fontSm,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppTheme.textMedium,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: settings.userCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرمز')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Activation status / form
          Padding(
            padding: const EdgeInsets.all(AppTheme.sp16),
            child: settings.isActivated
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.sp8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.accentGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppTheme.sp12),
                      const Text(
                        'التطبيق مفعّل',
                        style: TextStyle(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: AppTheme.fontLg,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: AppTheme.textHigh,
                          fontSize: AppTheme.fontMd,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'كود التفعيل',
                          prefixIcon: Icon(
                            Icons.vpn_key_rounded,
                            size: 18,
                          ),
                          hintText: 'أدخل كود التفعيل هنا',
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final success = await ref
                                .read(settingsProvider.notifier)
                                .activate(controller.text);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '✓ تم التفعيل بنجاح'
                                    : 'كود التفعيل غير صحيح'),
                                backgroundColor: success
                                    ? AppTheme.accentGreen
                                    : AppTheme.accentRed,
                              ),
                            );
                          },
                          icon:
                              const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('تفعيل الآن'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Office Data Card ──────────────────────────────────────────────────────────
class _OfficeDataCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController fbCtrl;
  final TextEditingController instaCtrl;
  final VoidCallback onSave;

  const _OfficeDataCard({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.fbCtrl,
    required this.instaCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          AppTextField(
            controller: nameCtrl,
            label: 'اسم المكتب',
            prefixIcon: Icons.business_rounded,
          ),
          AppTextField(
            controller: phoneCtrl,
            label: 'رقم الهاتف',
            prefixIcon: Icons.phone_rounded,
            isNumber: false,
          ),
          AppTextField(
            controller: fbCtrl,
            label: 'رابط فيسبوك',
            prefixIcon: Icons.link_rounded,
          ),
          AppTextField(
            controller: instaCtrl,
            label: 'رابط إنستغرام',
            prefixIcon: Icons.camera_alt_rounded,
          ),
          const SizedBox(height: AppTheme.sp4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('حفظ البيانات'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Backup Card ───────────────────────────────────────────────────────────────
class _BackupCard extends StatelessWidget {
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _BackupCard({required this.onExport, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _BackupTile(
            icon: Icons.backup_rounded,
            iconBg: AppTheme.accentGreen,
            title: 'أخذ نسخة احتياطية',
            subtitle: 'تصدير قاعدة البيانات الحالية',
            onTap: onExport,
          ),
          const Divider(
              height: 1, indent: AppTheme.sp16, endIndent: AppTheme.sp16),
          _BackupTile(
            icon: Icons.upload_file_rounded,
            iconBg: AppTheme.accentBlue,
            title: 'استيراد قاعدة البيانات',
            subtitle: 'استبدال البيانات بملف خارجي',
            onTap: onImport,
          ),
        ],
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackupTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16,
          vertical: AppTheme.sp16,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.sp8),
              decoration: BoxDecoration(
                color: iconBg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: iconBg, size: 20),
            ),
            const SizedBox(width: AppTheme.sp16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textHigh,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.fontMd,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textLow,
                      fontSize: AppTheme.fontXs,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left_rounded,
              color: AppTheme.textLow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.accentRed.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: AppTheme.accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.sp20,
              vertical: AppTheme.sp16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppTheme.accentRed,
                  size: 18,
                ),
                SizedBox(width: AppTheme.sp8),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontMd,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
