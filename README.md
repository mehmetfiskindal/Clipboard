# 🚀 Clipboard Manager for macOS

<div align="center">

[![macOS](https://img.shields.io/badge/macOS-14.0+-blue?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-blueviolet)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)](https://www.apple.com/macos/)

**Hafif, hızlı ve gizlilik odaklı macOS pano yöneticisi**

[📥 İndir](#kurulum) • [📖 Kullanım](#kullanım) • [✨ Özellikler](#özellikler) • [🛠️ Geliştirme](#geliştirme)

</div>

---

## 📸 Ekran Görüntüleri

> ⚠️ **Not:** Ekran görüntüleri yakında eklenecek!

<!-- 
<div align="center">
  <img src="screenshots/main-window.png" alt="Ana Pencere" width="600"/>
  <img src="screenshots/quick-search.png" alt="Hızlı Arama" width="400"/>
  <img src="screenshots/menubar.png" alt="Menü Bar" width="300"/>
</div>
-->

---

## ✨ Özellikler

### 📝 Clipboard Geçmişi
- 📋 Otomatik olarak kopyalanan metinleri kaydetme
- 🔍 Hızlı arama ile geçmişteki metinlere erişim
- ⏰ Zaman damgası ile organize edilmiş liste
- 🗑️ Kolay temizleme ve yönetim

### 🏷️ Snippet Yönetimi
- 💾 Sık kullanılan metin parçacıklarını kaydetme
- 🏷️ Kategorilere ayırma (yakında)
- 🚀 Tek tıkla panoya kopyalama

### ⚡ Hızlı Erişim
- **⌘⇧V** - Hızlı arama penceresini açma
- **🍎 Menü Bar** - Hızlı erişim menüsü
- **🎯 Global Kısayollar** - Her yerden erişim

### 🔒 Gizlilik ve Güvenlik
- 🏠 Tüm veriler yerel olarak saklanır
- ☁️ Bulut senkronizasyonu yok
- 🔐 Gizlilik odaklı tasarım
- 📱 SwiftData ile güvenli depolama

---

## 📦 Kurulum

### 🎯 Yöntem 1: Doğrudan İndirme (Önerilen)

1. [Releases](https://github.com/mehmetfiskindal/clipboard-manager/releases) sayfasına gidin
2. En son sürümü indirin (`ClipboardManager.dmg`)
3. DMG dosyasını açın ve uygulamayı **Applications** klasörüne sürükleyin

### 🛠️ Yöntem 2: Xcode ile Derleme

```bash
# Repoyu klonlayın
git clone https://github.com/mehmetfiskindal/clipboard-manager.git
cd clipboard-manager

# Xcode projesini açın
open Clipboard.xcodeproj

# Build edin ve çalıştırın
```

### ⚙️ Gerekli İzinler

İlk çalıştırmada uygulama **Erişilebilirlik** izni isteyecektir:

1. **Sistem Ayarları** → **Gizlilik ve Güvenlik** → **Erişilebilirlik**'e gidin
2. **Clipboard Manager** uygulamasını listede bulun ve etkinleştirin
3. 🔐 Mac şifrenizi girerek onaylayın

> 💡 **Bilgi:** Erişilebilirlik izni global klavye kısayollarını (⌘⇧V) algılamak için gereklidir.

---

## 🎮 Kullanım

### 🖱️ Ana Pencere
- **Geçmiş (History)**: Kopyalama geçmişinizi görüntüleyin ve arayın
- **Snippet'ler**: Kaydedilmiş metin parçacıklarınızı yönetin
- **Ayarlar**: Tercihlerinizi özelleştirin

### ⌨️ Klavye Kısayolları

| Kısayol | Açıklama |
|---------|----------|
| `⌘⇧V` | Hızlı arama penceresini aç/kapat |
| `⌘⇧C` | Seçili öğeyi kopyala |
| `⌘⇧D` | Seçili öğeyi sil |
| `⌘F` | Arama kutusuna odaklan |
| `Esc` | Pencereyi kapat |

### 🍎 Menü Bar
Menü bar simgesine (✂️) tıklayarak:
- Son kopyalanan metinlere hızlı erişim
- Hızlı arama penceresini açma
- Ayarlara erişim
- Uygulamayı tamamen kapatma

---

## 🛠️ Geliştirme

### 📋 Gereksinimler

- **macOS**: 14.0 (Sonoma) veya üzeri
- **Xcode**: 15.0 veya üzeri
- **Swift**: 5.9 veya üzeri
- **SwiftUI**: 5.0 veya üzeri

### 🏗️ Proje Yapısı

```
Clipboard/
├── Clipboard/
│   ├── Models/              # Veri modelleri
│   │   ├── ClipboardEntry.swift
│   │   └── Snippet.swift
│   ├── Services/            # İş mantığı
│   │   ├── ClipboardMonitor.swift
│   │   └── HotKeyManager.swift
│   ├── Views/               # SwiftUI görünümleri
│   │   ├── ClipboardHistoryView.swift
│   │   ├── SnippetsView.swift
│   │   ├── QuickSearchView.swift
│   │   ├── MenuBarView.swift
│   │   └── SettingsView.swift
│   ├── ClipboardApp.swift   # Ana uygulama
│   └── ContentView.swift    # Ana içerik
├── ClipboardTests/          # Unit testler
├── ClipboardUITests/        # UI testler
└── Clipboard.xcodeproj/     # Xcode projesi
```

### 🚀 Geliştirme Ortamı Kurulumu

```bash
# Repoyu fork edip klonlayın
git clone https://github.com/mehmetfiskindalniz/clipboard-manager.git
cd clipboard-manager

# Xcode ile açın
open Clipboard.xcodeproj

# Build edin
Cmd + B

# Çalıştırın
Cmd + R
```

### 🧪 Testleri Çalıştırma

```bash
# Tüm testleri çalıştır
Cmd + U (Xcode'da)
```

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Katkıda bulunmak için:

1. 🍴 Bu repoyu fork edin
2. 🌿 Yeni bir branch oluşturun (`git checkout -b feature/amazing-feature`)
3. 💾 Değişikliklerinizi commit edin (`git commit -m 'feat: Add amazing feature'`)
4. 📤 Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. 🔍 Pull Request açın

Katkı kuralları için [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına bakın.

---

## 🗺️ Yol Haritası

### ✅ Tamamlandı
- [x] Temel clipboard geçmişi takibi
- [x] Snippet yönetimi
- [x] Hızlı arama (⌘⇧V)
- [x] Menü bar entegrasyonu
- [x] SwiftData ile veri depolama

### 🚧 Geliştirme Aşamasında
- [ ] Klavye kısayollarını özelleştirme
- [ ] Snippet kategorileri
- [ ] İstatistikler ve analitik
- [ ] Dışa/içe aktarma özelliği

### 💡 Planlanan Özellikler
- [ ] iCloud senkronizasyonu (opsiyonel)
- [ ] Görsel (image) desteği
- [ ] Regex ile arama
- [ ] Eklenti sistemi
- [ ] Tema özelleştirme
- [ ] Birden fazla dil desteği

---

## 🐛 Hata Bildirimi

Bir hata bulduysanız lütfen [Issues](https://github.com/mehmetfiskindal/clipboard-manager/issues) sayfasından bildirin. Hata raporunuzda şunları ekleyin:

- macOS sürümü
- Uygulama sürümü
- Hatayı yeniden oluşturma adımları
- Beklenen ve gerçekleşen davranış
- Ekran görüntüleri (varsa)

---

## 📄 Lisans

Bu proje [MIT](LICENSE) lisansı altında lisanslanmıştır.

```
Copyright (c) 2026 Mehmet Fiskindal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
```

---

## 🙏 Teşekkürler

Bu projeyi mümkün kılan tüm açık kaynak kütüphanelere ve topluluğa teşekkürler!

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Modern UI framework
- [SwiftData](https://developer.apple.com/documentation/swiftdata) - Veri yönetimi
- [Apple Developer Documentation](https://developer.apple.com/documentation/) - Muhteşem dokümantasyon

---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!**

Made with ❤️ by [Mehmet Fiskindal](https://github.com/mehmetfiskindal)

</div>
