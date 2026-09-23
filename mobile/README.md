# Menzil Flutter programmasy

`mobile/` bukjasy feature-first gurluşda gurnalandyr:

```text
lib/
├── core/                 # tema, token saklaýjy, HTTP/API, sessiýa
├── features/
│   ├── auth/             # giriş we registrasiýa
│   ├── client/           # müşderiniň baş sahypasy we sargyt formasy
│   ├── courier/          # setire çykmak, GPS we sargyt lentasy
│   ├── tracking/         # müşderiniň WebSocket tracking sahypasy
│   └── shared/           # gaýtadan ulanylýan UI widget-lary
├── app.dart
└── main.dart
```

## Ilkinji başlatma

```sh
flutter create --platforms=android,ios .
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Native rugsatlary üçin [PLATFORM_SETUP.md](PLATFORM_SETUP.md) faýlyndaky ädimleri ýerine ýetiriň.

Soňky önümçilik çykarylyşyndan öň:

- API üçin diňe HTTPS/WSS ulanyň;
- tokeniň möhleti gutaranda refresh-token mehanizmini goşuň;
- tracking ekranyna hakyky karta provider-i goşuň;
- arka plandaky GPS üçin Android foreground service we iOS background location syýasatlaryny aýratyn düzüň.
