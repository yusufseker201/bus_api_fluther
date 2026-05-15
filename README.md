## Bus Density Mobile (Kahramanmaraş)

Bu Flutter mobil uygulaması, `bus_api` (Django REST Framework) backend’ini kullanarak **otobüs hattı/durak yoğunluklarını** gösterir ve kullanıcıların **konum doğrulamalı** yoğunluk raporu göndermesini sağlar.

### Backend API sözleşmesi (Django)

- **Login (Token)**: `POST /api/login/`
  - Body: `{ "email": "<email veya username>", "password": "<şifre>" }`
  - Response: `{ "token": "...", "user_id": 1 }`
- **Hatlar**: `GET /api/bus-lines/`
- **Duraklar**: `GET /api/bus-stops/`
- **Raporlar**: `GET /api/reports/`
- **Rapor gönder**: `POST /api/reports/submit/`
  - Headers: `Authorization: Token <token>`
  - Body:
    - `bus_line` (int)
    - `bus_stop` (int)
    - `density_level` (`GREEN|YELLOW|RED|BLACK`)
    - `user_lat` (float)
    - `user_lon` (float)
  - Not: Backend, durağa \(>200m\) uzakta raporu reddeder.

### Çalıştırma

Önce backend:

```bash
cd /home/ogrenci/Masaüstü/bus_api
./venv/bin/python manage.py runserver 127.0.0.1:8000
```

Sonra mobil uygulama:

```bash
cd /home/ogrenci/Masaüstü/bus_api_fluther
flutter run
```

### Not: Web’de beyaz ekran (CDN engeli)

Eğer Chrome’da boş beyaz ekran görüyorsanız ve loglarda şunlara benzer hatalar varsa:

- `Failed to fetch dynamically imported module .../canvaskit.js`
- `Failed to load font ... fonts.gstatic.com ...`

bu genelde **internet / kurumsal proxy / gstatic engeli** yüzündendir. Çözüm olarak Flutter’ın web kaynaklarını CDN’den değil yerelden kullanın:

```bash
flutter run -d chrome --no-web-resources-cdn
```

### Not: Android build sırasında SSL hatası

Eğer `flutter build apk` sırasında `SSLHandshakeException / PKIX path building failed` hatası alırsanız bu genellikle makinedeki **CA sertifikaları / kurumsal proxy** kaynaklıdır (kodla ilgili değil). Debian tabanlı sistemlerde çoğu zaman şunlar çözer:

```bash
sudo apt update && sudo apt install -y ca-certificates
```

#### API Base URL (gerekirse)

Android emulator için varsayılan backend adresi: `http://10.0.2.2:8000/api`

Gerçek cihazda / başka host’ta çalıştırmak için:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000/api
```

# bus_density_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
