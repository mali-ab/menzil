# Menzil mobil dizaýny

## Maksat

Interfeýs iki sany dürli iş tertibini iň pes çylşyrymlylyk bilen çözýär:

| Ulanyjy | Esasy hereket | Baş ekran |
| --- | --- | --- |
| Müşderi | Sargyt döretmek we hereketini görmek | Täze sargyt kartasy |
| Kurýer | Setire çykmak, laýyk sargydy kabul etmek | Elýeterlilik açary we sargyt lentasy |

## Wizual dil

- Esasy reňk: `#4F46E5` — ynamly, görünýän hereket düwmesi.
- Üstünlik/online reňki: `#11B981` — kurýeriň elýeterliligi, alyş nokady.
- Fon: `#F7F8FC`; kartlar ak fon bilen tapawutlanýar.
- Burç radiusy: uly bloklarda 24–28 px, input-da 16 px.
- Typografiýa: Material 3-nyň ulgam şrifti; sözbaşylar `800` agramly.
- Status diňe reňk bilen däl, nyşan we ýazgy bilen hem görkezilýär.

## Ekran akymy

```text
Giriş / hasap açmak
        |
        +-- Müşderi --> Baş sahypa --> Sargyt formasy --> Real wagt tracking
        |
        +-- Kurýer ----> Elýeterlilik açary --> Sargyt lentasy --> Kabul etmek
                                                          |
                                                          +--> GPS/WebSocket
```

## Dizaýn kararlary

1. Müşderiniň birinji CTA-sy diňe “Täze sargyt”. Bu esasy meseläni göni başlanýar.
2. Kurýerde ilkinji element “Elýeterli” açarydyr. GPS diňe kurýer setirde bolanda işledilýär.
3. Sargyt kartasynda bahasy, agramy we ugur iň öňde: kurýer gysga wagtda karar berip bilýär.
4. Kartanyň içinde ýaşyl/indigo nokatly dik ugur alyş we eltiş nokatlaryny tekstden has tiz okalýan edýär.
5. Kurýeriň “Aktiwler” bölüminde OpenStreetMap programma içinde görünýär: ýaşyl marker alyş, indigo marker eltiş nokadyny görkezýär. Daşarky browser-e geçmek talap edilmeýär.

## Giňeldilen funksiýalaryň UI akymy

- **Ulag:** sargyt formasyndaky ulag dropdown-y pyýada, welosiped, skuter, awtoulag we ýük ulagyny görkezýär.
- **Eskrou:** müşderi töleg sahypasynda “Pul eltiş tassyklanýança saklanýar” statusyny görmeli; kurýer bolsa OTP girizmek ýa-da foto ýükläp bilmelidir.
- **Multi-dostawka:** kurýer kartasynda “Ugra gabat gelýär” belligi, goşmaça wagt we aktiw sargytlaryň `2/3` hasaby görkezilmelidir.
- **Çat/jaň:** sargyt tracking sahypasynda iki düwme bolýar: “Habar” we “Jaň”. Olaryň hiç biri telefon belgisini görkezmeýär.
- **Çaýpuly/bonus:** eltiş tamamlanandan soň müşderä öňünden kesgitlenen çaýpuly düwmeleri we bonus balansy görkezilmelidir.
- **Karta:** kurýeriň sargyt kartasyndaky navigasiýa nyşany eltiş nokadyny OpenStreetMap-da açýar.
