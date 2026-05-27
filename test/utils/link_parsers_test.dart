import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/utils/link_parsers.dart';

void main() {
  group('LinkParser.parseProfileInput', () {
    test('keeps http subscriptions as remote urls', () {
      final input = LinkParser.parseProfileInput('https://example.com/sub?token=abc#WEPBOX');

      expect(input?.kind, ProfileInputKind.remoteUrl);
      expect(input?.value, 'https://example.com/sub?token=abc#WEPBOX');
      expect(input?.name, '');
    });

    test('decodes base64 remote subscriptions', () {
      final encoded = base64Encode(utf8.encode('https://example.com/sub?token=abc#WEPBOX'));

      final input = LinkParser.parseProfileInput(encoded);

      expect(input?.kind, ProfileInputKind.remoteUrl);
      expect(input?.value, 'https://example.com/sub?token=abc#WEPBOX');
    });

    test('imports direct proxy urls as local content', () {
      final input = LinkParser.parseProfileInput('vless://uuid@example.com:443?security=tls#node-a');

      expect(input?.kind, ProfileInputKind.localContent);
      expect(input?.value, 'vless://uuid@example.com:443?security=tls#node-a');
      expect(input?.name, 'node-a');
    });

    test('decodes base64 proxy subscriptions', () {
      final encoded = base64Encode(
        utf8.encode(
          'vmess://eyJhZGQiOiJleGFtcGxlLmNvbSJ9\n'
          'trojan://pass@example.com:443#trojan-node',
        ),
      );
      final input = LinkParser.parseProfileInput(encoded);

      expect(input?.kind, ProfileInputKind.localContent);
      expect(input?.value, contains('vmess://'));
      expect(input?.value, contains('trojan://'));
    });

    test('keeps v2ray proxy links separated when pasted on one line', () {
      final input = LinkParser.parseProfileInput(
        'vmess://eyJhZGQiOiJleGFtcGxlLmNvbSJ9 trojan://pass@example.com:443#trojan-node',
      );

      expect(input?.kind, ProfileInputKind.localContent);
      expect(input?.value, contains('\n'));
      expect(input?.value?.split('\n'), hasLength(2));
    });

    test('preserves clash yaml content', () {
      const yaml = '''
proxies:
  - name: node
    type: vmess
    server: example.com
    port: 443
proxy-groups:
  - name: auto
    type: select
    proxies:
      - node
''';

      final input = LinkParser.parseProfileInput(yaml);

      expect(input?.kind, ProfileInputKind.localContent);
      expect(input?.value, contains('proxy-groups:'));
      expect(input?.value, contains('    server: example.com'));
    });

    test('rejects unrelated text', () {
      final input = LinkParser.parseProfileInput('hello world');

      expect(input, isNull);
    });
  });
}
