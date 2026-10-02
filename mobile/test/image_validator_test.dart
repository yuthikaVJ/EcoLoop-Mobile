import 'package:flutter_test/flutter_test.dart';
import 'package:eco_loop/core/utils/image_validator.dart';

void main() {
  group('ImageValidator Tests', () {
    test('accepts valid PNG image under 5 MB', () {
      final result = ImageValidator.validateImage(
        fileName: 'profile_pic.png',
        byteLength: 2 * 1024 * 1024, // 2 MB
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('accepts valid JPG and JPEG images under 5 MB', () {
      final resultJpg = ImageValidator.validateImage(
        fileName: 'banner.jpg',
        byteLength: 4 * 1024 * 1024, // 4 MB
      );
      expect(resultJpg.isValid, isTrue);
      expect(resultJpg.errorMessage, isNull);

      final resultJpeg = ImageValidator.validateImage(
        fileName: 'photo.JPEG', // uppercase test
        byteLength: 1024,
      );
      expect(resultJpeg.isValid, isTrue);
      expect(resultJpeg.errorMessage, isNull);
    });

    test('rejects non-PNG/JPEG extensions like webp, gif, bmp, pdf', () {
      final formats = ['image.webp', 'anim.gif', 'photo.bmp', 'doc.pdf', 'script.exe'];
      for (final file in formats) {
        final result = ImageValidator.validateImage(
          fileName: file,
          byteLength: 1024,
        );
        expect(result.isValid, isFalse, reason: 'Expected $file to be rejected');
        expect(result.errorMessage, 'Images should be in PNG or JPEG format.');
      }
    });

    test('rejects images equal to or greater than 5 MB', () {
      // Exactly 5 MB
      final resultExact5Mb = ImageValidator.validateImage(
        fileName: 'large.png',
        byteLength: 5 * 1024 * 1024,
      );
      expect(resultExact5Mb.isValid, isFalse);
      expect(resultExact5Mb.errorMessage, 'Images should be less than 5 MB.');

      // Greater than 5 MB
      final resultOver5Mb = ImageValidator.validateImage(
        fileName: 'large.jpeg',
        byteLength: 6 * 1024 * 1024,
      );
      expect(resultOver5Mb.isValid, isFalse);
      expect(resultOver5Mb.errorMessage, 'Images should be less than 5 MB.');
    });
  });
}
