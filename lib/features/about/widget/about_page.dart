import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/features/app_update/notifier/app_update_state.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AboutPage extends HookConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final appInfo = ref.watch(appInfoProvider).requireValue;
    final appUpdate = ref.watch(appUpdateNotifierProvider);

    ref.listen(appUpdateNotifierProvider, (_, next) async {
      if (!context.mounted) return;
      switch (next) {
        case AppUpdateStateAvailable(:final versionInfo) ||
            AppUpdateStateIgnored(:final versionInfo):
          return await ref
              .read(dialogNotifierProvider.notifier)
              .showNewVersion(
                currentVersion: appInfo.presentVersion,
                newVersion: versionInfo,
                canIgnore: false,
              );
        case AppUpdateStateError(:final error):
          return CustomToast.error(t.presentShortError(error)).show(context);
        case AppUpdateStateNotAvailable():
          return CustomToast.success(
            t.pages.about.notAvailableMsg,
          ).show(context);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 112),
          children: [
            Text(
              '关于 WEPBOX',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const Gap(28),
            Row(
              children: [
                Image.asset(
                  'assets/images/wepbox_logo.png',
                  width: 56,
                  height: 56,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.common.appTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Gap(4),
                      Text('版本 ${appInfo.presentVersion}'),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(28),
            _AboutTile(
              title: '检查更新',
              subtitle: '从 WEPBOX GitHub Release 获取最新版本',
              trailing: switch (appUpdate) {
                AppUpdateStateChecking() => const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                _ => const Icon(FluentIcons.arrow_sync_24_regular),
              },
              onTap: appInfo.release.allowCustomUpdateChecker
                  ? () async => await ref
                        .read(appUpdateNotifierProvider.notifier)
                        .check()
                  : null,
            ),
            _AboutTile(
              title: '源代码仓库',
              subtitle: Constants.githubUrl,
              trailing: const Icon(FluentIcons.open_24_regular),
              onTap: () async =>
                  await UriUtils.tryLaunch(Uri.parse(Constants.githubUrl)),
            ),
            _AboutTile(
              title: '开源许可',
              subtitle: '保留 Hiddify 上游许可与鸣谢',
              trailing: const Icon(FluentIcons.open_24_regular),
              onTap: () async =>
                  await UriUtils.tryLaunch(Uri.parse(Constants.licenseUrl)),
            ),
            _AboutTile(
              title: '复制调试信息',
              subtitle: '用于你主动反馈问题时粘贴设备和版本信息',
              trailing: const Icon(Icons.copy_rounded),
              onTap: () async => await Clipboard.setData(
                ClipboardData(text: appInfo.format()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const Gap(6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
