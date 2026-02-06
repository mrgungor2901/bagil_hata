// Bağıl Hata Hesaplayıcısı Testleri

import 'package:flutter_test/flutter_test.dart';
import 'package:bagil_hata/main.dart';

void main() {
  group('truncateToTwoDecimals Testleri', () {
    test('İki ondalık basamağa yuvarlama - tam sayı', () {
      expect(truncateToTwoDecimals(12), '12.00');
    });

    test('İki ondalık basamağa yuvarlama - bir basamak', () {
      expect(truncateToTwoDecimals(12.5), '12.50');
    });

    test('İki ondalık basamağa yuvarlama - üç basamak kesiliyor', () {
      expect(truncateToTwoDecimals(12.555), '12.55');
    });

    test('İki ondalık basamağa yuvarlama - sıfırdan küçük', () {
      expect(truncateToTwoDecimals(0.4), '0.40');
    });

    test('İki ondalık basamağa yuvarlama - negatif sayı', () {
      expect(truncateToTwoDecimals(-1.234), '-1.23');
    });

    test('İki ondalık basamağa yuvarlama - tam iki basamak', () {
      expect(truncateToTwoDecimals(12.34), '12.34');
    });
  });

  group('Bağıl Hata Hesaplama Mantığı', () {
    test('Uygun aralık içinde - pozitif hata', () {
      const double dispenser = 12.50;
      const double mastermetre = 12.45;
      final double hata = ((dispenser - mastermetre) / mastermetre) * 100;
      
      expect(hata >= -1 && hata <= 1, true);
    });

    test('Uygun aralık içinde - negatif hata', () {
      const double dispenser = 12.40;
      const double mastermetre = 12.45;
      final double hata = ((dispenser - mastermetre) / mastermetre) * 100;
      
      expect(hata >= -1 && hata <= 1, true);
    });

    test('Uygun aralık dışında - çok yüksek', () {
      const double dispenser = 15.0;
      const double mastermetre = 12.0;
      final double hata = ((dispenser - mastermetre) / mastermetre) * 100;
      
      expect(hata > 1, true);
    });

    test('Uygun aralık dışında - çok düşük', () {
      const double dispenser = 10.0;
      const double mastermetre = 12.0;
      final double hata = ((dispenser - mastermetre) / mastermetre) * 100;
      
      expect(hata < -1, true);
    });

    test('Tam eşit değerler - sıfır hata', () {
      const double dispenser = 12.50;
      const double mastermetre = 12.50;
      final double hata = ((dispenser - mastermetre) / mastermetre) * 100;
      
      expect(hata, 0.0);
    });
  });
}
