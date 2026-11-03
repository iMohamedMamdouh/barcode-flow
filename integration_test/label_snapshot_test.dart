// Reference test for the current Bluetooth (TSPL) label output.
//
// Needs the real `printing` plugin (PDF rasterization), so it runs on a device
// or desktop, not in plain `flutter test`:
//
//   flutter test integration_test -d linux     (xvfb-run on a headless box)
//   flutter test integration_test -d <android-device-id>
//
// It checks the TSPL structure and compares a SHA-256 of the bytes against
// `_goldens`. On a platform without goldens it prints the hashes to record.
// Any intentional label change must update the goldens in the same commit.

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:wasilaah_finishing/core/utils/tspl_label_builder.dart';

import '../test/support/tspl_parser.dart';

class _Fixture {
  const _Fixture(
    this.id,
    this.productName,
    this.barcode, {
    this.variantName,
    this.quantity = 1,
  });

  final String id;
  final String productName;
  final String barcode;
  final String? variantName;
  final int quantity;
}

const _fixtures = [
  _Fixture('code128_no_variant', 'Walnut Shoe Storage Bench', 'WS-SHOE-001'),
  _Fixture(
    'ean13_arabic_variant',
    'AKILA Office Desk',
    '5901234123457',
    variantName: 'اللون: أبيض • المقاس: كبير',
    quantity: 2,
  ),
  _Fixture('ean8_no_variant', 'Round Wall Mirror', '96385074'),
];

/// SHA-256 of the TSPL bytes per `Platform.operatingSystem` and fixture.
/// Rasterization is done by the platform, so each platform has its own.
const _goldens = <String, Map<String, String>>{
  'linux': {
    'code128_no_variant':
        'bb3add86ed902ef1400eb7b6f63eeb5397efa3c033d0ec9ed0c3ceb82adfc40c',
    'ean13_arabic_variant':
        '8ad3d7a7ffd9360063a7fca910ef5f30c76f0a47d6f7334f43e6e27104b26e32',
    'ean8_no_variant':
        'a1b133d1b419514115fb755f7ed11f75cddf3bbdf73522a95f714784ab6c7d46',
  },
  // Fill in from the LABEL_HASH lines after the first run on the reference
  // Android device used for printing.
  'android': {},
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final f in _fixtures) {
    testWidgets('TSPL label: ${f.id}', (tester) async {
      final bytes = await tester.runAsync(
        () => TsplLabelBuilder.buildBarcodeLabel(
          f.barcode,
          productName: f.productName,
          variantName: f.variantName,
          quantity: f.quantity,
        ),
      );
      expect(bytes, isNotNull);

      final program = TsplProgram.parse(bytes!);
      final hasVariant = f.variantName != null;

      expect(program.names, [
        'SIZE', 'GAP', 'SPEED', 'DENSITY', 'DIRECTION', 'REFERENCE',
        'CODEPAGE', 'CLS',
        'BITMAP', // logo
        'BITMAP', // product name
        if (hasVariant) 'BITMAP', // variant
        'BITMAP', // barcode
        'BLOCK', // human-readable digits
        'BITMAP', // "made in Egypt"
        'PRINT',
      ]);
      expect(program.first('SIZE')!.args, '75.0 mm,130.0 mm');
      expect(program.first('GAP')!.args, '3.0 mm,0');
      expect(program.first('DENSITY')!.args, '8');
      expect(program.first('PRINT')!.args, '${f.quantity},1');
      expect(program.first('BLOCK')!.line, endsWith('"${f.barcode}"'));

      final widthDots = TsplLabelBuilder.labelWidthDots;
      final heightDots = TsplLabelBuilder.labelHeightDots;
      final bitmaps = program.bitmaps;
      for (final b in bitmaps) {
        expect(b.x % 8, 0, reason: '${b.line} x not byte-aligned');
        expect(b.x + b.widthDots, lessThanOrEqualTo(widthDots), reason: b.line);
        expect(b.y + b.height, lessThanOrEqualTo(heightDots), reason: b.line);
        expect(b.blackPixels, greaterThan(0), reason: '${b.line} is blank');
      }
      // Elements are stacked top to bottom without overlapping.
      for (var k = 1; k < bitmaps.length; k++) {
        expect(
          bitmaps[k].y,
          greaterThanOrEqualTo(bitmaps[k - 1].y + bitmaps[k - 1].height),
          reason: '${bitmaps[k].line} overlaps the previous element',
        );
      }

      // KNOWN BUG (fix planned with the new label engine, phase 5): the
      // barcode BITMAP header is sent with a trailing CRLF, so the printer
      // takes those 2 bytes as image data and shifts the barcode ~16 dots.
      final barcodeBitmap = bitmaps[hasVariant ? 3 : 2];
      expect(
        bitmaps.where((b) => b.leadingCrlf),
        [barcodeBitmap],
        reason: 'Only the barcode bitmap is expected to have the CRLF bug',
      );

      _writePreview(f.id, bitmaps, widthDots, heightDots);

      final hash = sha256.convert(bytes).toString();
      final golden = _goldens[Platform.operatingSystem]?[f.id];
      // ignore: avoid_print
      print('LABEL_HASH ${Platform.operatingSystem} ${f.id} $hash');
      if (golden != null) {
        expect(hash, golden, reason: 'Label bytes changed for ${f.id}');
      }
    });
  }
}

/// Desktop only: writes a PNG of the bitmap layers to build/label_snapshots/
/// for a visual check (BLOCK text is drawn by the printer and not included,
/// and the barcode is drawn where it was meant to be, without the CRLF shift).
void _writePreview(String id, List<TsplBitmap> bitmaps, int w, int h) {
  if (!(Platform.isLinux || Platform.isMacOS || Platform.isWindows)) return;
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  for (final b in bitmaps) {
    for (var py = 0; py < b.height; py++) {
      for (var px = 0; px < b.widthDots; px++) {
        if (b.isBlack(px, py) && b.x + px < w && b.y + py < h) {
          image.setPixelRgb(b.x + px, b.y + py, 0, 0, 0);
        }
      }
    }
  }
  final dir = Directory('build/label_snapshots')..createSync(recursive: true);
  File('${dir.path}/$id.png').writeAsBytesSync(img.encodePng(image));
}
