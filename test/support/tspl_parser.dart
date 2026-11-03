import 'dart:convert';
import 'dart:typed_data';

/// Minimal TSPL stream parser used by tests to validate generated labels.
///
/// Text commands are `\r\n` terminated. `BITMAP x,y,widthBytes,height,mode,`
/// is followed by `widthBytes * height` raw bytes and then `\r\n`.
class TsplProgram {
  TsplProgram(this.commands);

  final List<TsplCommand> commands;

  List<String> get names => commands.map((c) => c.name).toList();
  List<TsplBitmap> get bitmaps => commands.whereType<TsplBitmap>().toList();

  TsplCommand? first(String name) {
    for (final c in commands) {
      if (c.name == name) return c;
    }
    return null;
  }

  static TsplProgram parse(List<int> bytes) {
    final commands = <TsplCommand>[];
    var i = 0;

    int indexOf(List<int> pattern, int from) {
      for (var p = from; p <= bytes.length - pattern.length; p++) {
        var ok = true;
        for (var k = 0; k < pattern.length; k++) {
          if (bytes[p + k] != pattern[k]) {
            ok = false;
            break;
          }
        }
        if (ok) return p;
      }
      return -1;
    }

    const crlf = [13, 10];
    final bitmapPrefix = ascii.encode('BITMAP ');

    while (i < bytes.length) {
      final isBitmap = indexOf(bitmapPrefix, i) == i;
      if (!isBitmap) {
        final end = indexOf(crlf, i);
        if (end < 0) {
          throw FormatException('Unterminated command at byte $i');
        }
        final line = utf8.decode(bytes.sublist(i, end));
        commands.add(TsplCommand(line));
        i = end + 2;
        continue;
      }

      // Header: BITMAP x,y,wb,h,mode,
      var commas = 0;
      var p = i;
      while (commas < 5) {
        if (p >= bytes.length) throw FormatException('Bad BITMAP at $i');
        if (bytes[p] == 44) commas++;
        p++;
      }
      final header = ascii.decode(bytes.sublist(i, p));
      final nums = header
          .substring('BITMAP '.length, header.length - 1)
          .split(',')
          .map(int.parse)
          .toList();

      // Per TSPL the data starts right after the comma. A CRLF here means the
      // header was sent as a full command line (see `leadingCrlf`).
      var leadingCrlf = false;
      if (p + 1 < bytes.length && bytes[p] == 13 && bytes[p + 1] == 10) {
        leadingCrlf = true;
        p += 2;
      }

      final length = nums[2] * nums[3];
      if (p + length + 2 > bytes.length) {
        throw FormatException('BITMAP data truncated at $i');
      }
      final data = Uint8List.fromList(bytes.sublist(p, p + length));
      p += length;
      if (bytes[p] != 13 || bytes[p + 1] != 10) {
        throw FormatException('BITMAP at $i not followed by CRLF');
      }
      commands.add(
        TsplBitmap(
          header.substring(0, header.length - 1),
          x: nums[0],
          y: nums[1],
          widthBytes: nums[2],
          height: nums[3],
          mode: nums[4],
          data: data,
          leadingCrlf: leadingCrlf,
        ),
      );
      i = p + 2;
    }

    return TsplProgram(commands);
  }
}

class TsplCommand {
  TsplCommand(this.line);

  final String line;

  String get name => line.split(' ').first;
  String get args => line.length > name.length ? line.substring(name.length + 1) : '';
}

class TsplBitmap extends TsplCommand {
  TsplBitmap(
    super.line, {
    required this.x,
    required this.y,
    required this.widthBytes,
    required this.height,
    required this.mode,
    required this.data,
    required this.leadingCrlf,
  });

  final int x;
  final int y;
  final int widthBytes;
  final int height;
  final int mode;
  final Uint8List data;

  /// True when a CRLF was sent between the header and the data. A printer
  /// reads those two bytes as image data, shifting the bitmap by 16 dots.
  final bool leadingCrlf;

  int get widthDots => widthBytes * 8;

  /// Pixel is black (TSPL: bit 0 = print, 1 = blank).
  bool isBlack(int px, int py) {
    final byte = data[py * widthBytes + (px ~/ 8)];
    return (byte & (1 << (7 - px % 8))) == 0;
  }

  int get blackPixels {
    var n = 0;
    for (var py = 0; py < height; py++) {
      for (var px = 0; px < widthDots; px++) {
        if (isBlack(px, py)) n++;
      }
    }
    return n;
  }
}
