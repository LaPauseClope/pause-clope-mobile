import 'package:flutter_test/flutter_test.dart';
import 'package:la_pause_clope/utils/validators.dart';

void main() {
  group('Validators.isValidNickname', () {
    test('Nickname vide est invalide', () {
      expect(Validators.isValidNickname(''), false);
      expect(Validators.isValidNickname('   '), false);
    });

    test('Nickname correct est valide', () {
      expect(Validators.isValidNickname('Jean'), true);
    });
  });

  group('Validators.isShortNickname', () {
    test('Nickname court détecté', () {
      expect(Validators.isShortNickname('Al'), true);
    });

    test('Nickname long détecté', () {
      expect(Validators.isShortNickname('Alexandre'), false);
    });
  });
}
