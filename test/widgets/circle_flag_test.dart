// test/widgets/circle_flag_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/ui/widgets/circle_flag.dart';

void main() {
  group('CircleFlag asset resolution', () {
    test('resolves language codes to SVG assets', () {
      expect(CircleFlag.resolveAsset('ja'), 'assets/flags/jp.svg');
      expect(CircleFlag.resolveAsset('ko'), 'assets/flags/kr.svg');
      expect(CircleFlag.resolveAsset('zh'), 'assets/flags/cn.svg');
      expect(CircleFlag.resolveAsset('vi'), 'assets/flags/vn.svg');
      expect(CircleFlag.resolveAsset('en'), 'assets/flags/us.svg');
      expect(CircleFlag.resolveAsset('es'), 'assets/flags/es.svg');
      expect(CircleFlag.resolveAsset('fr'), 'assets/flags/fr.svg');
      expect(CircleFlag.resolveAsset('de'), 'assets/flags/de.svg');
      expect(CircleFlag.resolveAsset('id'), 'assets/flags/id.svg');
      expect(CircleFlag.resolveAsset('ru'), 'assets/flags/ru.svg');
      expect(CircleFlag.resolveAsset('th'), 'assets/flags/th.svg');
      expect(CircleFlag.resolveAsset('it'), 'assets/flags/it.svg');
      expect(CircleFlag.resolveAsset('pt'), 'assets/flags/pt.svg');
    });

    test('resolves ISO country codes', () {
      expect(CircleFlag.resolveAsset('jp'), 'assets/flags/jp.svg');
      expect(CircleFlag.resolveAsset('kr'), 'assets/flags/kr.svg');
      expect(CircleFlag.resolveAsset('cn'), 'assets/flags/cn.svg');
      expect(CircleFlag.resolveAsset('vn'), 'assets/flags/vn.svg');
      expect(CircleFlag.resolveAsset('us'), 'assets/flags/us.svg');
      expect(CircleFlag.resolveAsset('gb'), 'assets/flags/gb.svg');
      expect(CircleFlag.resolveAsset('ca'), 'assets/flags/ca.svg');
      expect(CircleFlag.resolveAsset('au'), 'assets/flags/au.svg');
      expect(CircleFlag.resolveAsset('br'), 'assets/flags/br.svg');
    });

    test('resolves emoji flag characters', () {
      expect(CircleFlag.resolveAsset('🇯🇵'), 'assets/flags/jp.svg');
      expect(CircleFlag.resolveAsset('🇰🇷'), 'assets/flags/kr.svg');
      expect(CircleFlag.resolveAsset('🇨🇳'), 'assets/flags/cn.svg');
      expect(CircleFlag.resolveAsset('🇻🇳'), 'assets/flags/vn.svg');
      expect(CircleFlag.resolveAsset('🇺🇸'), 'assets/flags/us.svg');
      expect(CircleFlag.resolveAsset('🇬🇧'), 'assets/flags/gb.svg');
    });

    test('resolves direct asset paths', () {
      expect(CircleFlag.resolveAsset('assets/flags/jp.svg'), 'assets/flags/jp.svg');
      expect(CircleFlag.resolveAsset('assets/flags/vn.svg'), 'assets/flags/vn.svg');
    });

    test('handles unknown, empty or auto values gracefully', () {
      expect(CircleFlag.resolveAsset(null), isNull);
      expect(CircleFlag.resolveAsset(''), isNull);
      expect(CircleFlag.resolveAsset('   '), isNull);
      expect(CircleFlag.resolveAsset('auto'), isNull);
      expect(CircleFlag.resolveAsset('xyz_unknown'), isNull);
    });
  });
}
