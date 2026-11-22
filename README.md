# System Metali Mobile

Aplikacja mobilna do zarządzania inwestycjami w metale szlachetne, tworzona we Flutterze i Darcie.

Projekt powstaje w ramach przedmiotu **Technologie Aplikacji Mobilnych**. Jego celem jest przygotowanie uproszczonej wersji mobilnej wcześniejszej aplikacji desktopowej **System Metali**, napisanej w Pythonie.

Oryginalny projekt: https://github.com/Kruchyx/system-metali

## Cel projektu

Celem jest częściowa migracja aplikacji desktopowej na platformę mobilną, z zachowaniem podstawowych funkcji zarządzania portfelem inwestycyjnym. Projekt obejmuje również dokumentację procesu migracji, testy oraz przygotowanie aplikacji na Androida.

## Aktualny stan — v0.1

Pierwsza wersja demonstracyjna zawiera:

- ekran portfela inwestycyjnego,
- prezentację inwestycji w złoto i srebro,
- obliczanie wartości zakupu i aktualnej wyceny,
- wyświetlanie zysku lub straty oraz ROI,
- nawigację między zakładkami Portfel, Transakcje, Kursy i Wykresy.

Aktualne dane są demonstracyjne. Zakładki Transakcje, Kursy i Wykresy zostaną rozbudowane w kolejnych etapach.

Aplikacja została uruchomiona w przeglądarce Chrome. Przeprowadzona lokalnie analiza kodu nie wykazała problemów, a dwa testy zakończyły się powodzeniem.

## Planowane funkcjonalności

- Dodawanie i usuwanie transakcji.
- Automatyczne aktualizowanie wartości portfela.
- Trwały zapis danych.
- Wyświetlanie kursów złota i srebra.
- Wizualizacja danych na wykresach.
- Przygotowanie wersji APK na Androida.
- Rozważenie integracji z Firebase / Google Cloud.

## Technologie

- **Flutter i Dart** — aplikacja mobilna.
- **Material Design 3** — interfejs użytkownika.
- **GitHub** — repozytorium i historia rozwoju projektu.
- **Firebase / Google Cloud** — planowana integracja.

## Uruchomienie projektu

Wymagane jest zainstalowane środowisko Flutter.

W katalogu projektu należy wykonać polecenia:

`flutter pub get`

`flutter run -d chrome`

Analiza kodu:

`flutter analyze`

Uruchomienie testów:

`flutter test`

## Dokumentacja migracji

Projekt będzie dokumentował przejście z aplikacji desktopowej Python / CustomTkinter do Fluttera.

Dokumentacja obejmie porównanie architektury, opis przeniesionych funkcji, screenshoty obu wersji oraz wyniki testów.

## Zespół projektowy

- **Oskar Kruszczyński — 60582** — https://github.com/Kruch
