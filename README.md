# Menzil

Menzil — müşderi bilen kurýeri birleşdirýän eltip beriş hyzmatynyň başlangyç monorepo-sy. Taslama iki garaşsyz programmadan durýar:

```text
menzil/
├── api/                  # Go REST/WebSocket API, PostgreSQL we PostGIS
│   ├── cmd/api/          # programmanyň giriş nokady
│   ├── internal/         # auth, orders, tracking, middleware
│   ├── migrations/       # PostgreSQL/PostGIS schema
│   ├── .env.example      # API gurşaw sazlamasy
│   └── docker-compose.yml
├── mobile/               # Flutter Android/iOS programmasy
│   ├── lib/core/         # tema, API, token we sessiýa
│   └── lib/features/     # auth, client, courier, tracking
└── Makefile              # umumy development komandalar
```

## Gerekli gurallar

- Go 1.25 ýa-da täze;
- Flutter SDK we Android Studio / Xcode;
- Docker Desktop ýa-da Docker Engine (PostgreSQL üçin).

## API gurmak we işletmek

1. PostgreSQL/PostGIS-i işlediň:

   ```sh
   cd api
   docker compose up -d
   ```

2. API gurşaw faýlyny taýýarlaň:

   ```sh
   cp .env.example .env
   set -a; . ./.env; set +a
   ```

3. Go baglylyklaryny ýükläp, API-ni başladyň:

   ```sh
   go mod tidy
   go run ./cmd/api
   ```

API standart boýunça `http://localhost:8080` salgysynda açylýar. Şol bir komandalar repo-nyň kökünden hem işledilip bilner:

```sh
make api-db
make api-seed
make api-run
```

`make api-run` `api/.env` bar bolsa ony awtomatik ýükleýär. `make api-run` we `make api-test` ilki `go mod tidy` işledip, `api/go.sum` dependency hash faýlyny awtomatik döredýär. Ony git commit-e goşuň.

PostgreSQL paroly diňe volume ilkinji gezek döredilende bellenýär. Öňki lokal volume başga parol bilen döredilen bolsa we standart `menzil` parolyna dolanmak isleseňiz, maglumaty pozmazdan şuny işlediň:

```sh
make api-db-sync-default-password
```

Öz parolyňyzy ulanmak üçin `api/.env` faýlynda `POSTGRES_PASSWORD` we `DATABASE_URL`-daky paroly birmeňzeş ediň.

`api/migrations/*.up.sql` faýllary diňe täze PostgreSQL volume döredilende konteýner tarapyndan awtomatik ýerine ýetirilýär; `.down.sql` faýllary hiç wagt init wagtynda işlemeýär. Öndürilişde aýratyn migration guralyny ulanmak maslahat berilýär.

Öňden işleýän lokal baza üçin täze funksiýalaryň migration-yny aýratyn işlediň:

```sh
cd api
docker compose exec -T postgres psql -U menzil -d menzil < migrations/000002_delivery_features.up.sql
```

## Development seed maglumatlary

Migration-lar ýerine ýetirilenden soň lokal demo hasaplaryny we Aşgabat boýunça iki sargydy goşmak üçin:

```sh
make api-seed
```

`make api-seed` PostgreSQL healthcheck-i üstünlikli tamamlanýança garaşýar. Konteýneriň ilkinji işe goýberilişinde PostGIS migration-lary sebäpli bu birnäçe sekunt alyp biler.

Soňkyra şu hasaplar bilen girip bolýar:

| Rol | Telefon | Parol | Ulag |
| --- | --- | --- | --- |
| Müşderi | `+99360000001` | `password` | — |
| Kurýer | `+99360000002` | `password` | Awtoulag |
| Kurýer | `+99360000003` | `password` | Skuter |

Seed diňe development üçin niýetlenendir; ol `api/seeds/development.sql` faýlynda ýerleşýär we Docker başlananda awtomatik işlemeýär. Ol üç ulanyjyny, iki sargydy, status taryhyny, escrow/proof, kurýer lokasiýasyny, çat/jaň sessiýasyny, bonus we çaýpuly döredýär. Öň seed işledilen bolsa, demo maglumatlaryny täzelemek üçin `make api-seed` komandany ýene bir gezek işlediň.

## Flutter gurmak we işletmek

1. Flutter native taslama faýllaryny birinji gezek dörediň we paketleri ýükläň:

   ```sh
   cd mobile
   flutter create --platforms=android,ios .
   flutter pub get
   ```

2. Android/iOS geolokasiýa rugsatlaryny [mobile/PLATFORM_SETUP.md](mobile/PLATFORM_SETUP.md) boýunça goşuň.

3. Programmany işlediň:

   ```sh
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   ```

Android emulýatorynda `10.0.2.2` host kompýuteriniň `localhost` salgysydyr. iOS simulýatorynda `http://localhost:8080`, hakyky enjamda bolsa kompýuteriň lokal IP salgysy ýa-da HTTPS development salgysy ulanylmaly.

Repo kökünden gysga komandalar:

```sh
make mobile-init
make mobile-run-android
```

Soňky enjam birikdirilmedik Linux development kompýuterinde UI synagy üçin:

```sh
make mobile-linux-init
make mobile-run
```

Chrome arkaly web development üçin:

```sh
make mobile-web-init
make mobile-run-web
```

`mobile-run` Linux desktop-a bilkastlaýyn `http://localhost:8080` bilen birikýär. Android emulýatory üçin `mobile-run-android` ulanyň, sebäbi onuň host kompýuter salgysy `10.0.2.2` bolýar. Chrome lokal development-de `localhost` API-a birikýär; deployment-de HTTPS/WSS we anyk CORS origin allowlist-i hökmanydyr. Linux build-i üçin bir gezek `sudo apt install -y libsecret-1-dev libsecret-1-0` gerek bolýar; bu `flutter_secure_storage` paketiniň native garaşlylygydyr.

## API endpoint-lary

| Usul | Salgysy | Rol | Maksat |
| --- | --- | --- | --- |
| POST | `/v1/auth/register` | açyk | Müşderi ýa-da kurýer bellige almak |
| POST | `/v1/auth/login` | açyk | Access token almak |
| POST | `/v1/orders` | client | Sargyt döretmek |
| GET | `/v1/courier/orders/available` | courier | Ulagyna laýyk sargytlar |
| PUT | `/v1/courier/availability` | courier | Elýeterlilik ýagdaýyny üýtgetmek |
| POST | `/v1/courier/orders/:id/accept` | courier | Sargydy kabul etmek |
| POST | `/v1/courier/orders/:id/status` | courier | Sargyt ýagdaýyny üýtgetmek |
| GET | `/v1/courier/ws/location` | courier | Kurýeriň geolokasiýa WebSocket-i |
| GET | `/v1/orders/:id/tracking/ws` | client/courier | Real wagt tracking WebSocket-i |

Goragly endpoint-larda şu header ulanylýar:

```text
Authorization: Bearer <access_token>
```

Mobil dizaýn ýörelgeleri üçin [mobile/DESIGN.md](mobile/DESIGN.md) faýlyna serediň.

## Giňeldilen mümkinçilikler

- Pyýada, welosiped, skuter, awtoulag we ýük ulagy boýunça sargyt/kurýer süzgüji;
- Eskrou, OTP/foto subutnamasy üçin schema binýady;
- Bir kurýer üçin atomar görnüşde çäklendirilen iň köp üç aktiw sargyt;
- Telefon belgilerini açmazdan içki çat we VoIP call-room modeli;
- Bonus, çaýpuly we QR töleg reference modeli;
- Kurýer kartasyndan OpenStreetMap-a geçýän navigasiýa düwmesi.

Giňeldilen API maglumat modeli we önümçilik düzgünleri [api/FEATURES.md](api/FEATURES.md) faýlynda düşündirilýär.
