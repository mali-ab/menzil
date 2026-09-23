# Android/iOS platforma sazlamasy

Soňky `mobile/` bukjasynda diňe Flutter/Dart çeşme faýllary ýerleşýär. Platforma bukjalaryny döretmek üçin bu bukjanyň içinde bir gezek aşakdakyny işlediň:

```sh
flutter create --platforms=android,ios .
flutter pub get
```

Soňkyra `android/app/src/main/AndroidManifest.xml` faýlyndaky `<manifest>` elementine goşuň:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

Eger kurýeriň geolokasiýasy programma fonunda hem iberilmeli bolsa, Android üçin `ACCESS_BACKGROUND_LOCATION` we foreground service konfigurasiýasy gerek bolar. Bu rugsat diňe hakyky iş zerurlygy bar ýagdaýynda ulanylmaly.

`ios/Runner/Info.plist` içine goşuň:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Kurýeriň sargytlary eltip beriş hereketini görkezmek üçin ýerleşiş maglumatyny ulanýar.</string>
```

Soňkyra API salgysyny gurşaw arkaly beriň:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Android emulýatorynda `10.0.2.2`, iOS simulýatorynda adatça `localhost` ulanylýar. Hakyky enjamda kompýuteriň lokal IP salgysyny ýa-da HTTPS arkaly açyk development salgysyny beriň.

## Linux arkaly UI synagy

Android/iOS enjamy bolmadyk development kompýuterinde Linux desktop build-i ulanyp bolýar:

```sh
flutter create --platforms=linux .
flutter pub get
flutter run -d linux --dart-define=API_BASE_URL=http://localhost:8080
```

## Chrome/Web arkaly synag

Web platformasyny dörediň we Chrome-da işlediň:

```sh
flutter create --platforms=web .
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Brauzer WebSocket-i `Authorization` header iberip bilmeýär. Şonuň üçin programma WebSocket tokenini diňe `/ws` endpoint-laryna `access_token` query parametri bilen iberýär; backend hem bu parametr diňe WebSocket üçin kabul edýär. Deployment-de token syzmaz ýaly diňe HTTPS/WSS ulanyň, proxy log-larynda query parametrlerini maskalaň we API-nyň CORS origin sanawyny diňe öz domenleriňiz bilen çäklendiriň.
