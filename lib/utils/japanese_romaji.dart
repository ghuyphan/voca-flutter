// lib/utils/japanese_romaji.dart
// 1:1 port of ../lingua-tube/src/app/shared/utils/japanese-romaji.ts

const Map<String, String> _digraphMap = {
  'きゃ': 'kya',
  'きゅ': 'kyu',
  'きょ': 'kyo',
  'ぎゃ': 'gya',
  'ぎゅ': 'gyu',
  'ぎょ': 'gyo',
  'しゃ': 'sha',
  'しゅ': 'shu',
  'しょ': 'sho',
  'じゃ': 'ja',
  'じゅ': 'ju',
  'じょ': 'jo',
  'ちゃ': 'cha',
  'ちゅ': 'chu',
  'ちょ': 'cho',
  'にゃ': 'nya',
  'にゅ': 'nyu',
  'にょ': 'nyo',
  'ひゃ': 'hya',
  'ひゅ': 'hyu',
  'ひょ': 'hyo',
  'びゃ': 'bya',
  'びゅ': 'byu',
  'びょ': 'byo',
  'ぴゃ': 'pya',
  'ぴゅ': 'pyu',
  'ぴょ': 'pyo',
  'みゃ': 'mya',
  'みゅ': 'myu',
  'みょ': 'myo',
  'りゃ': 'rya',
  'りゅ': 'ryu',
  'りょ': 'ryo',
  'うぃ': 'wi',
  'うぇ': 'we',
  'うぉ': 'wo',
  'ゔぁ': 'va',
  'ゔぃ': 'vi',
  'ゔぇ': 've',
  'ゔぉ': 'vo',
  'ゔゅ': 'vyu',
  'う゛ぁ': 'va',
  'う゛ぃ': 'vi',
  'う゛ぇ': 've',
  'う゛ぉ': 'vo',
  'う゛ゅ': 'vyu',
  'ふぁ': 'fa',
  'ふぃ': 'fi',
  'ふぇ': 'fe',
  'ふぉ': 'fo',
  'ふゅ': 'fyu',
  'てぃ': 'ti',
  'でぃ': 'di',
  'とぅ': 'tu',
  'どぅ': 'du',
  'ちぇ': 'che',
  'しぇ': 'she',
  'じぇ': 'je',
  'つぁ': 'tsa',
  'つぃ': 'tsi',
  'つぇ': 'tse',
  'つぉ': 'tso',
};

const Map<String, String> _monographMap = {
  'あ': 'a',
  'い': 'i',
  'う': 'u',
  'え': 'e',
  'お': 'o',
  'か': 'ka',
  'き': 'ki',
  'く': 'ku',
  'け': 'ke',
  'こ': 'ko',
  'が': 'ga',
  'ぎ': 'gi',
  'ぐ': 'gu',
  'げ': 'ge',
  'ご': 'go',
  'さ': 'sa',
  'し': 'shi',
  'す': 'su',
  'せ': 'se',
  'そ': 'so',
  'ざ': 'za',
  'じ': 'ji',
  'ず': 'zu',
  'ぜ': 'ze',
  'ぞ': 'zo',
  'た': 'ta',
  'ち': 'chi',
  'つ': 'tsu',
  'て': 'te',
  'と': 'to',
  'だ': 'da',
  'ぢ': 'ji',
  'づ': 'zu',
  'で': 'de',
  'ど': 'do',
  'な': 'na',
  'に': 'ni',
  'ぬ': 'nu',
  'ね': 'ne',
  'の': 'no',
  'は': 'ha',
  'ひ': 'hi',
  'ふ': 'fu',
  'へ': 'he',
  'ほ': 'ho',
  'ば': 'ba',
  'び': 'bi',
  'ぶ': 'bu',
  'べ': 'be',
  'ぼ': 'bo',
  'ぱ': 'pa',
  'ぴ': 'pi',
  'ぷ': 'pu',
  'ぺ': 'pe',
  'ぽ': 'po',
  'ま': 'ma',
  'み': 'mi',
  'む': 'mu',
  'め': 'me',
  'も': 'mo',
  'や': 'ya',
  'ゆ': 'yu',
  'よ': 'yo',
  'ら': 'ra',
  'り': 'ri',
  'る': 'ru',
  'れ': 're',
  'ろ': 'ro',
  'わ': 'wa',
  'ゐ': 'wi',
  'ゑ': 'we',
  'を': 'o',
  'ん': 'n',
  'ゔ': 'vu',
  'ぁ': 'a',
  'ぃ': 'i',
  'ぅ': 'u',
  'ぇ': 'e',
  'ぉ': 'o',
  'ゃ': 'ya',
  'ゅ': 'yu',
  'ょ': 'yo',
  'ゎ': 'wa',
};

const String _smallTsu = 'っ';
const String _longVowelMark = 'ー';
final RegExp _kanaTextRegex = RegExp(
  r'^[\u3040-\u30FFー\s・。、？！「」『』（）〔〕［］｛｝〈〉《》【】…ー-]+$',
  unicode: true,
);

String katakanaToHiragana(String text) {
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code >= 0x30A1 && code <= 0x30F6) {
      buffer.writeCharCode(code - 0x60);
    } else {
      buffer.writeCharCode(code);
    }
  }
  return buffer.toString();
}

String _getNextRomaji(String source, int index) {
  if (index >= source.length) return '';
  final current = source[index];
  final next = (index + 1 < source.length) ? source[index + 1] : null;

  if (next != null) {
    final pair = '$current$next';
    if (_digraphMap.containsKey(pair)) {
      return _digraphMap[pair]!;
    }
  }

  return _monographMap[current] ?? '';
}

String _getConsonantForSokuon(String nextRomaji) {
  if (nextRomaji.isEmpty) return '';
  if (nextRomaji.startsWith('ch')) return 'c';
  final first = nextRomaji[0].toLowerCase();
  if ('bcdfghjklmnpqrstvwxyz'.contains(first)) {
    return first;
  }
  return '';
}

String _getLastVowel(String text) {
  for (int i = text.length - 1; i >= 0; i--) {
    final ch = text[i].toLowerCase();
    if ('aeiou'.contains(ch)) {
      return ch;
    }
  }
  return '';
}

bool isJapaneseKanaText(String? text) {
  return text != null && text.isNotEmpty && _kanaTextRegex.hasMatch(text);
}

String toJapaneseRomaji(String? text) {
  if (text == null || text.isEmpty) return '';

  final normalized = katakanaToHiragana(text);
  final buffer = StringBuffer();

  for (int index = 0; index < normalized.length; index++) {
    final current = normalized[index];

    if (current == _smallTsu) {
      buffer.write(_getConsonantForSokuon(_getNextRomaji(normalized, index + 1)));
      continue;
    }

    if (current == _longVowelMark) {
      buffer.write(_getLastVowel(buffer.toString()));
      continue;
    }

    if (index + 1 < normalized.length) {
      final pair = normalized.substring(index, index + 2);
      if (_digraphMap.containsKey(pair)) {
        buffer.write(_digraphMap[pair]!);
        index++;
        continue;
      }
    }

    final romaji = _monographMap[current];
    if (romaji == null) {
      buffer.write(current);
      continue;
    }

    if (romaji == 'n') {
      final nextRomaji = _getNextRomaji(normalized, index + 1);
      if (nextRomaji.isNotEmpty && 'aeiouy'.contains(nextRomaji[0].toLowerCase())) {
        buffer.write("n'");
      } else {
        buffer.write('n');
      }
      continue;
    }

    buffer.write(romaji);
  }

  return buffer.toString();
}

String? getJapaneseRomaji(String? reading, String? surface) {
  final source = reading ?? (isJapaneseKanaText(surface) ? surface : null);
  if (source == null || source.isEmpty) return null;
  final romaji = toJapaneseRomaji(source);
  return romaji.isNotEmpty ? romaji : null;
}
