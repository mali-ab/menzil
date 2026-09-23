# Giňeldilen hyzmat düzgünleri

## Ulag boýunça paýlamak

`transport_types` indi `foot`, `bicycle`, `scooter`, `car`, `truck` görnüşlerini saklaýar. Sargyt diňe kurýeriň `transport_type_code` bahasy bilen deň gelende görkezilýär. Ulag görnüşini müşderi ýüküň ölçegine we agramyna görä saýlaýar.

## Eskrou we eltiş subutnamasy

`escrow_transactions` tölegiň ýagdaýyny saklaýar:

```text
pending -> held -> released
                 -> refunded
pending -> failed
```

`delivery_proofs` bir gezeklik OTP hash-ini ýa-da faýl ammaryndaky foto URL-ini saklaýar. Parol hiç wagt açyk görnüşde maglumatlar bazasynda saklanmaly däl: diňe Argon2id ýa-da bcrypt hash-i ýazylmaly. OTP barlanandan ýa-da foto moderator tarapyndan kabul edilenden soň töleg provider adapter-i `held` tölegini `released` edip bilmeli.

Hakyky töleg geçirmek üçin ýerli bank/PSP-niň API açarlary we hukuki şertnamasy gerek. Şol sebäpli migration diňe ygtybarly maglumat modelini goşýar; ol özbaşdak hiç bir hakyky puly göçürmeýär.

## Multi-dostawka

`courier_profiles.max_active_orders` standart boýunça `3`. Kurýer sargyt kabul eden pursadynda profil setiri `FOR UPDATE` bilen gulplanýar we aktiw (`accepted`, `to_pickup`, `delivering`) sargytlaryň sany atomar görnüşde barlanýar. Şeýlelikde parallel request arkaly çäkden geçmek mümkin däl.

Soňky optimizasiýa tapgyrynda PostGIS bilen alyş/eltiş nokatlaryny we ugur provider-iň ETA maglumatlaryny ulanyp, diňe eýýämki ugra ýakyn sargytlary teklip etmek gerek.

## Anonim aragatnaşyk

`order_chat_conversations` we `order_chat_messages` sargyt boýunça içki çat üçin, `order_call_sessions` bolsa VoIP provider-iň wagtlaýyn room ID-si üçin niýetlenendir. API diňe şol sargydyň müşderisine we bellenen kurýerine rugsat bermeli; telefon belgileri response-a goşulmaly däl.

## Bonuslar we çaýpuly

`loyalty_accounts` häzirki balansy, `loyalty_events` bolsa üýtgeşmeleriň audit ýazgysyny saklaýar. `courier_tips` sargyt, kurýer we QR payment reference bilen baglanýar. Bonus ýa-da çaýpulyň hakyky tölegi hem escrow ýaly provider callback-i bilen `paid` ýagdaýyna geçirilmelidir.
