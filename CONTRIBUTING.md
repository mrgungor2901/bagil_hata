# Katkıda Bulunma Rehberi

Teşekkürler! Bu belge, katkıda bulunmak isteyen geliştiriciler için kısa bir rehberdir.

1) Nasıl Başlayacaksınız
- Repository'yi fork'layın ve yerel olarak klonlayın.
- Yeni bir branch oluşturun: `feature/adi` veya `fix/issue-123` gibi.

2) Kod Stili ve Kontroller
- `flutter analyze` komutunu çalıştırarak statik analiz hatalarını giderin.
- Yazdığınız değişiklikler için uygun birim testleri ekleyin ve `flutter test` ile çalıştırın.

3) Commit ve Pull Request (PR) Rehberi
- Anlaşılır, kısa commit mesajları kullanın. Örnek: `fix: düzeltme açıklaması` veya `feat: yeni özellik açıklaması`.
- PR açıklamasına yapılan değişiklikleri, ilgili issue numarasını ve test adımlarını ekleyin.
- PR açıldıktan sonra review taleplerine yanıt verin ve istenirse düzeltmeleri içeren yeni commit'ler ekleyin.

4) Görseller ve Asset Eklemek
- Ekran görüntülerini `assets/screenshots/` dizinine ekleyin.
- Görsel adlarını README'de belirtilen adlarla eşleştirin (`main_screen.png`, `result_screen.png`, `settings_screen.png`).
- Görsellerin boyutunu 1080x1920 veya daha düşük tutun; PNG/JPG tercih edin.

5) Güvenlik ve Gizlilik
- Gizli anahtarları, token'ları veya kullanıcı verilerini repoya asla eklemeyin.

6) Yardım ve İletişim
- Sorularınızı issue olarak açın, hızlı dönüş sağlamaya çalışacağız.

Teşekkürler — katkılarınız proje için değerlidir!