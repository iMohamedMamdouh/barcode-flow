import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'tspl_parser.dart';

void main() {
  List<int> program(List<Object> parts) => [
    for (final p in parts) ...(p is String ? utf8.encode(p) : p as List<int>),
  ];

  test('parses text commands and a bitmap payload', () {
    final bytes = program([
      'SIZE 75.0 mm,130.0 mm\r\n',
      'CLS\r\n',
      'BITMAP 8,16,2,2,0,',
      [0x7F, 0xFF, 0xFF, 0xFE],
      '\r\n',
      'PRINT 3,1\r\n',
    ]);

    final p = TsplProgram.parse(bytes);
    expect(p.names, ['SIZE', 'CLS', 'BITMAP', 'PRINT']);
    final bmp = p.bitmaps.single;
    expect([bmp.x, bmp.y, bmp.widthBytes, bmp.height], [8, 16, 2, 2]);
    expect(bmp.leadingCrlf, isFalse);
    expect(bmp.isBlack(0, 0), isTrue);
    expect(bmp.isBlack(1, 0), isFalse);
    expect(bmp.isBlack(15, 1), isTrue);
    expect(bmp.blackPixels, 2);
    expect(p.first('PRINT')!.args, '3,1');
  });

  test('flags a CRLF between BITMAP header and data', () {
    final bytes = program([
      'BITMAP 0,0,1,1,0,\r\n',
      [0xFF],
      '\r\n',
    ]);
    expect(TsplProgram.parse(bytes).bitmaps.single.leadingCrlf, isTrue);
  });

  test('rejects truncated bitmap data', () {
    final bytes = program(['BITMAP 0,0,4,4,0,', [0xFF, 0xFF], '\r\n']);
    expect(() => TsplProgram.parse(bytes), throwsFormatException);
  });
}
