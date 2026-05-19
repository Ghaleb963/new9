import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../properties/providers/property_provider.dart';
import '../../../core/widgets/app_form_widgets.dart';
import '../../../core/widgets/app_loading_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../services/backup_service.dart';
import '../../../core/utils/permission_helper.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fbController = TextEditingController();
  final _instaController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
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
          const SizedBox(height: AppTheme.sp32),
        ],
      ),
    );
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  Future<void> _exportDatabase(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final granted = await requestStoragePermission();
        if (!granted) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('صلاحية التخزين مطلوبة لتصدير النسخة الاحتياطية'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
          return;
        }
      }

      final ts = DateTime.now()
          .toLocal()
          .toString()
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName = 'realestate_backup_$ts.db';

      String? savePath;
      if (Platform.isAndroid || Platform.isIOS) {
        final directoryPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'اختر مجلد حفظ النسخة الاحتياطية',
        );
        if (directoryPath != null) {
          savePath = '$directoryPath/$fileName';
        }
      } else {
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية',
          fileName: fileName,
        );
      }

      if (savePath == null) return;

      await BackupService.exportTo(savePath);

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
    if (Platform.isAndroid) {
      final granted = await requestStoragePermission();
      if (!granted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('صلاحية التخزين مطلوبة لاستيراد النسخة الاحتياطية'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        return;
      }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final selectedPath = result.files.single.path!;

    final isValid = await BackupService.isValidBackup(selectedPath);
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
    showAppLoadingDialog(context, message: 'جاري الاستيراد...');

    try {
      await BackupService.restoreFrom(selectedPath);
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


