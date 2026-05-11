class BrailleConverter {
  static const Map<String, String> _textToBrailleMap = {
    'a': '⠁', 'b': '⠃', 'c': '⠉', 'd': '⠙', 'e': '⠑',
    'f': '⠋', 'g': '⠛', 'h': '⠓', 'i': '⠊', 'j': '⠚',
    'k': '⠅', 'l': '⠇', 'm': '⠍', 'n': '⠝', 'o': '⠕',
    'p': '⠏', 'q': '⠟', 'r': '⠗', 's': '⠎', 't': '⠞',
    'u': '⠥', 'v': '⠧', 'w': '⠺', 'x': '⠭', 'y': '⠽', 'z': '⠵',
    '0': '⠴', '1': '⠂', '2': '⠆', '3': '⠒', '4': '⠲',
    '5': '⠢', '6': '⠖', '7': '⠶', '8': '⠦', '9': '⠔',
    ' ': ' ', '.': '⠲', ',': '⠂', ';': '⠆', ':': '⠒',
    '!': '⠖', '?': '⠦', '-': '⠤', '(': '⠶', ')': '⠦'
  };

  static final Map<String, String> _brailleToTextMap =
  _textToBrailleMap.map((key, value) => MapEntry(value, key));

  static String textToBraille(String text) {
    return text.toLowerCase().split('').map((char) {
      return _textToBrailleMap[char] ?? char;
    }).join('');
  }

  static String brailleToText(String braille) {
    return braille.split('').map((char) {
      return _brailleToTextMap[char] ?? char;
    }).join('');
  }

  static bool isBrailleCharacter(String char) {
    return _brailleToTextMap.containsKey(char);
  }

  static String getBrailleVisualization(String brailleChar) {
    return brailleChar;
  }
}