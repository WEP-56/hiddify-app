import 'dart:convert';

import 'package:hiddify/utils/validators.dart';

typedef ProfileLink = ({String url, String name});
typedef ProfileInput = ({ProfileInputKind kind, String value, String name});

enum ProfileInputKind { remoteUrl, localContent }

// TODO: test and improve
abstract class LinkParser {
  static const proxySchemes = {
    'ss',
    'ssconf',
    'vmess',
    'vless',
    'trojan',
    'tuic',
    'hy2',
    'hysteria2',
    'hy',
    'hysteria',
    'ssh',
    'wg',
    'awg',
    'shadowtls',
    'mieru',
    'warp',
  };

  static String generateSubShareLink(String url, [String? name]) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final modifiedUri = Uri(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      query: uri.query,
      fragment: name ?? uri.fragment,
    );
    // return 'wepbox://import/$modifiedUri';
    return '$modifiedUri';
  }

  // protocols schemas
  static const protocols = ['wepbox', 'hiddify', 'v2ray', 'v2rayn', 'v2rayng', 'clash', 'clashmeta', 'sing-box'];

  static ProfileLink? parse(String link) {
    return simple(link) ?? deep(link);
  }

  static ProfileInput? parseProfileInput(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return null;

    if (parse(input) case final link? when _isRemoteSubscriptionUrl(link.url)) {
      return (kind: ProfileInputKind.remoteUrl, value: link.url, name: link.name);
    }

    final decoded = safeDecodeBase64(input).trim();
    final content = _looksLikeProfileContent(decoded) ? decoded : input;

    if (parse(decoded) case final link? when _isRemoteSubscriptionUrl(link.url)) {
      return (kind: ProfileInputKind.remoteUrl, value: link.url, name: link.name);
    }

    if (!_looksLikeProfileContent(content)) return null;

    return (kind: ProfileInputKind.localContent, value: _normalizeLocalContent(content), name: _extractName(content));
  }

  static ProfileLink? simple(String link) {
    if (!isUrl(link)) return null;
    final uri = Uri.parse(link.trim());
    return (url: uri.toString(), name: uri.queryParameters['name'] ?? '');
  }

  static ProfileLink? deep(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    final queryParams = uri.queryParameters;
    switch (uri.scheme) {
      case 'wepbox' || 'hiddify':
        if (queryParams.containsKey('url')) {
          return (url: queryParams['url']!, name: queryParams['name'] ?? '');
        } else {
          return (url: uri.path.substring(1) + (uri.hasQuery ? "?${uri.query}" : ""), name: uri.fragment);
        }
      case 'v2ray' || 'v2rayn' || 'v2rayng' || 'clash' || 'clashmeta' || 'sing-box':
        return queryParams.containsKey('url') ? (url: queryParams['url']!, name: queryParams['name'] ?? '') : null;
      default:
        return null;
    }
  }

  static bool _isRemoteSubscriptionUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool _isProxyUrlLine(String line) {
    final uri = Uri.tryParse(line.trim());
    return uri != null && proxySchemes.contains(uri.scheme.toLowerCase());
  }

  static bool _looksLikeProfileContent(String value) {
    final content = value.trim();
    if (content.isEmpty) return false;
    if (content.split(RegExp(r'\s+')).any(_isProxyUrlLine)) return true;
    if (content.startsWith('{') || content.startsWith('[')) return true;
    return content.contains('proxies:') ||
        content.contains('proxy-groups:') ||
        content.contains('outbounds:') ||
        content.contains('"outbounds"') ||
        content.contains('mixed-port:') ||
        content.contains('port:');
  }

  static String _normalizeLocalContent(String content) {
    if (_looksStructuredProfileContent(content)) {
      return content.trim().replaceAll('\r\n', '\n');
    }
    final proxySchemePattern = proxySchemes.map(RegExp.escape).join('|');
    return content
        .trim()
        .replaceAll(RegExp('\\s+(?=(?:$proxySchemePattern)://)'), '\n')
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  static bool _looksStructuredProfileContent(String content) {
    final value = content.trimLeft();
    if (value.startsWith('{') || value.startsWith('[')) return true;
    return value.contains('proxies:') ||
        value.contains('proxy-groups:') ||
        value.contains('outbounds:') ||
        value.contains('"outbounds"') ||
        value.contains('mixed-port:') ||
        value.contains('port:');
  }

  static String _extractName(String content) {
    for (final token in content.split(RegExp(r'[\r\n\t ]+'))) {
      final uri = Uri.tryParse(token.trim());
      if (uri == null || !proxySchemes.contains(uri.scheme.toLowerCase())) {
        continue;
      }
      if (uri.hasFragment) return Uri.decodeComponent(uri.fragment);
    }
    return '';
  }
}

String safeDecodeBase64(String str) {
  try {
    final compact = str.replaceAll(RegExp(r'\s+'), '');
    return utf8.decode(base64Decode(base64.normalize(compact)));
  } catch (e) {
    return str;
  }
}
