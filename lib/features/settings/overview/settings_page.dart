import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/features/settings/notifier/reset_tunnel/reset_tunnel_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 112),
          children: [
            Text(
              '全局设置',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),
            _SectionLabel('基础'),
            SettingsSection(
              title: '通用偏好',
              subtitle: '语言、主题、通知、日志与连接测试',
              icon: Icons.tune_rounded,
              namedLocation: context.namedLocation('general'),
            ),
            SettingsSection(
              title: '入站与 TUN',
              subtitle: 'VPN/TUN、系统代理与本地端口',
              icon: Icons.input_rounded,
              namedLocation: context.namedLocation('inboundOptions'),
            ),
            const SizedBox(height: 26),
            _SectionLabel('网络策略'),
            SettingsSection(
              title: '路由规则',
              subtitle: '分流地区、广告拦截、IPv6 与应用代理',
              icon: Icons.route_rounded,
              namedLocation: context.namedLocation('routeOptions'),
            ),
            SettingsSection(
              title: 'DNS 规则',
              subtitle: '远程 DNS、直连 DNS、FakeDNS',
              icon: Icons.dns_rounded,
              namedLocation: context.namedLocation('dnsOptions'),
            ),
            SettingsSection(
              title: t.pages.settings.tlsTricks.title,
              subtitle: 'TLS 分片、SNI 与 Padding',
              icon: Icons.content_cut_rounded,
              namedLocation: context.namedLocation('tlsTricks'),
            ),
            SettingsSection(
              title: t.pages.settings.warp.title,
              subtitle: 'Cloudflare WARP 出站策略',
              icon: Icons.cloud_rounded,
              namedLocation: context.namedLocation('warpOptions'),
            ),
            if (PlatformUtils.isIOS)
              Material(
                child: ListTile(
                  title: Text(t.pages.settings.resetTunnel),
                  leading: const Icon(Icons.autorenew_rounded),
                  onTap: () async {
                    await ref.read(resetTunnelNotifierProvider.notifier).run();
                  },
                ),
              ),
            if (Breakpoint(context).isMobile()) ...[
              const SizedBox(height: 26),
              _SectionLabel('维护'),
              SettingsSection(
                title: t.pages.logs.title,
                subtitle: '查看运行日志',
                icon: Icons.description_rounded,
                namedLocation: context.namedLocation('logs'),
              ),
              SettingsSection(
                title: t.pages.about.title,
                subtitle: '版本、许可与开源信息',
                icon: Icons.info_rounded,
                namedLocation: context.namedLocation('about'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends HookConsumerWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.namedLocation,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String namedLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.go(namedLocation),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
