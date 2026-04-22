class AttributeTranslator {
  AttributeTranslator._();

  static const _phraseTranslations = <String, String>{
    'seat fabric': 'قماش المقعد',
    'beige color': 'لون بيج',
    'light wood': 'خشب فاتح',
    'dark wood': 'خشب غامق',
    'dark brown': 'بني غامق',
    'light brown': 'بني فاتح',
    'natural wood': 'خشب طبيعي',
    'Hand rest': 'مسند اليد',
  };

  static const _wordTranslations = <String, String>{
    'color': 'اللون',
    'colour': 'اللون',
    'size': 'المقاس',
    'width': 'العرض',
    'height': 'الارتفاع',
    'depth': 'العمق',
    'length': 'الطول',
    'weight': 'الوزن',
    'material': 'الخامة',
    'fabric': 'القماش',
    'wood': 'خشب',
    'metal': 'معدن',
    'glass': 'زجاج',
    'small': 'صغير',
    'medium': 'وسط',
    'large': 'كبير',
    'white': 'أبيض',
    'black': 'أسود',
    'brown': 'بني',
    'beige': 'بيج',
    'grey': 'رمادى',
    'gray': 'رمادى',
    'red': 'أحمر',
    'blue': 'أزرق',
    'green': 'أخضر',
    'yellow': 'أصفر',
    'pink': 'وردي',
    'cm': 'سم',
    'transperant': 'شفاف',
    'without': 'بدون',
    'with': 'مع',
    'fixed': 'ثابت',
    'movable': 'متحرك',
    'and': 'و',
    'or': 'أو',
  };

  static String translate(String input) {
    var result = input;

    for (final entry in _phraseTranslations.entries) {
      result = _replaceAll(result, entry.key, entry.value);
    }

    for (final entry in _wordTranslations.entries) {
      result = _replaceAll(result, entry.key, entry.value);
    }

    return result.trim();
  }

  /// Case-insensitive replacement that preserves surrounding structure.
  static String _replaceAll(String source, String from, String to) {
    final lower = source.toLowerCase();
    final fromLower = from.toLowerCase();
    final buffer = StringBuffer();
    var start = 0;

    while (true) {
      final index = lower.indexOf(fromLower, start);
      if (index == -1) {
        buffer.write(source.substring(start));
        break;
      }
      buffer.write(source.substring(start, index));
      buffer.write(to);
      start = index + from.length;
    }

    return buffer.toString();
  }
}
