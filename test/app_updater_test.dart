import 'package:flutter_test/flutter_test.dart';
import 'package:zoc/desktop/app_updater.dart';

void main() {
  group('AppUpdater.isNewer', () {
    test('returns false when versions are identical', () {
      expect(AppUpdater.isNewer('1.5.9', '1.5.9'), isFalse);
    });

    test('returns false when version has "v" prefix and matches', () {
      expect(AppUpdater.isNewer('v1.5.9', '1.5.9'), isFalse);
      expect(AppUpdater.isNewer('1.5.9', 'v1.5.9'), isFalse);
      expect(AppUpdater.isNewer('V1.5.9', '1.5.9'), isFalse);
    });

    test('ignores build numbers (+N)', () {
      expect(AppUpdater.isNewer('1.5.9', '1.5.9+1'), isFalse);
      expect(AppUpdater.isNewer('1.5.9+2', '1.5.9+1'), isFalse);
    });

    test('handles pre-release suffixes correctly', () {
      expect(AppUpdater.isNewer('1.5.9', '1.5.9-beta'), isFalse);
    });

    test('returns true when remote version is higher', () {
      expect(AppUpdater.isNewer('1.5.10', '1.5.9'), isTrue);
      expect(AppUpdater.isNewer('1.6.0', '1.5.9'), isTrue);
      expect(AppUpdater.isNewer('2.0.0', '1.5.9'), isTrue);
      expect(AppUpdater.isNewer('1.5.9', '1.0.0'), isTrue);
    });

    test('returns false when remote version is lower', () {
      expect(AppUpdater.isNewer('1.5.8', '1.5.9'), isFalse);
      expect(AppUpdater.isNewer('1.4.9', '1.5.9'), isFalse);
      expect(AppUpdater.isNewer('0.9.9', '1.5.9'), isFalse);
    });

    test('handles versions with whitespace safely', () {
      expect(AppUpdater.isNewer(' 1.5.9 ', '1.5.9'), isFalse);
    });
  });
}
