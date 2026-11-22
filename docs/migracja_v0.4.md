# System Metali Mobile v0.4 — trwały zapis danych

## Cel

Wersja v0.4 rozwija v0.3 o zapis transakcji, ręcznie ustawionych cen złota i srebra i informacji, czy ceny zostały zmienione. Dzięki temu ponowne uruchomienie aplikacji nie przywraca poprzedniej listy transakcji ani cen referencyjnych, jeśli użytkownik zmienił dane.

## Rozwiązanie techniczne

- Nowa zależność `shared_preferences` i jej interfejs `SharedPreferencesAsync`.
- Nowy plik `lib/portfolio_storage.dart`, odpowiedzialny za zapis i odczyt pojedynczego tekstu JSON.
- Obiekt `PortfolioSnapshot` zawiera listę transakcji oraz obie ceny PLN/oz z flagami ręcznej edycji.
- Zapis posiada pole `schemaVersion: 1`, ułatwiające przyszłe migracje formatu.
- Przy starcie aplikacja odczytuje dane, a w trakcie odczytu pokazuje wskaźnik ładowania.
- Po dodaniu, usunięciu lub zmianie kursu uruchamiany jest zapis nowego stanu; zapisy są wykonywane w kolejności.
- Jeśli nie ma jeszcze zapisu, aplikacja pokazuje dwa dotychczasowe zakupy demonstracyjne. Gdy użytkownik usunie wszystkie zakupy, zapisana pusta lista pozostaje pusta po restarcie.
- Gdy odczyt lub zapis zakończy się błędem, użytkownik otrzymuje komunikat.

## Lokalizacja danych

- Android: pamięć ustawień aplikacji zarządzana przez pakiet `shared_preferences`.
- Chrome / Flutter Web: pamięć przeglądarki (LocalStorage), powiązana z **konkretnym adresem i portem strony**.
- Do testu restartu w Chrome należy stale używać tego samego portu, np. `flutter run -d chrome --web-port 8080`. Jeśli uruchomienie użyje innego portu, strona może nie widzieć wcześniej zapisanych danych.
- Dane są lokalne: nie synchronizują się między Chrome, Androidem ani między urządzeniami. Usunięcie danych witryny lub aplikacji może usunąć zapis.

## Porównanie z desktopowym Pythonem

Oryginał zapisuje transakcje w SQLite (`backend.py`). W wersji mobilnej v0.4 używamy prostszego lokalnego magazynu JSON, odpowiedniego dla prototypu i niewielkiej liczby transakcji. Nie jest to migracja bazy SQLite 1:1 ani system synchronizacji chmurowej; taki etap można zrealizować później (np. Firebase).

## Scenariusze testowe

1. Dodać transakcję i sprawdzić, czy pozostaje w aplikacji po ponownym uruchomieniu.
2. Usunąć transakcję, uruchomić ponownie i potwierdzić, że nie wróciła.
3. Usunąć wszystkie transakcje — po restarcie portfel ma pozostać pusty.
4. Zmienić ręcznie cenę złota i srebra — po restarcie nowe ceny nadal mają być widoczne.
5. Sprawdzić obliczenia PLN/kg i PLN/oz oraz ROI z v0.3.
6. Uruchomić `flutter analyze` oraz `flutter test` po dodaniu zależności.

## Ograniczenia

`shared_preferences` jest magazynem prostych ustawień, a nie transakcyjną bazą danych i nie gwarantuje trwałości zapisów w każdej awarii. Do docelowego systemu finansowego lepiej użyć bazy danych, kopii zapasowych i walidacji finansowej opartej na typach dziesiętnych. Wersja v0.4 pozostaje projektem dydaktycznym z cenami referencyjnymi, które nie są aktualizowane automatycznie.

## Przyszłe etapy

v0.5 — wykresy; v0.6 — uruchomienie Android i APK; v0.7 — integracja Google Cloud/Firebase (jeśli pozostanie w wymaganiach prowadzącego); dalsze prace — dokumentacja z końcowych ekranów aplikacji.
