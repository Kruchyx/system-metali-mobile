# System Metali Mobile v0.3 — jednostki i ceny

## Cel zmian

Rozbudowa formularza transakcji o jednostki oz i kg dla złota i srebra, wprowadzenie orientacyjnych cen opartych na danych rynkowych oraz uruchomienie ekranu Kursy.

## Porównanie z oryginalnym projektem Python

Oryginalny `backend.py` zawiera `convert_amount_to_kg_oz` oraz `convert_price_to_oz` i przechowuje ilość oraz cenę po przeliczeniu do uncji trojańskiej. Podobny schemat zastosowano w Dart: `toTroyOunces` i `priceToPlnOz`. W Dart stosujemy dokładniejszy współczynnik `1 kg = 32.1507465686 oz t` (w projekcie Python zaokrąglony do `32.1507`).

Kurs używany do wyceny jest wspólny dla wszystkich transakcji w danym metalu; po zmianie ceny złota lub srebra aktualizują się portfel i ROI.

## Referencyjne ceny początkowe (20 listopada 2026)

- Złoto XAU/USD: **3520.57 USD/oz**
- Srebro XAG/USD: **41.113 USD/oz**
- Średni kurs USD/PLN NBP: **4.0613** (tabela **226/A/NBP/2026**)
- Wynik przeliczenia: złoto **14298.09 PLN/oz**, srebro **166.97 PLN/oz** (po zaokrągleniu do grosza)

Źródła:
- https://metalcharts.org/xauusd-historical-data/2026
- https://metalcharts.org/xagusd-historical-data/2026
- https://nbp.pl/statystyka-i-sprawozdawczosc/kursy/tabela-a/

Te ceny **nie aktualizują się automatycznie**. W weekend 22 listopada 2026 r. punktem odniesienia pozostaje sesja 20 listopada. Nie są to ceny detaliczne sztabek lub monet; nie obejmują marży, podatków ani spreadu. Użytkownik może ręcznie zmienić kurs w zakładce Kursy. Ręczna zmiana nie jest jeszcze trwale zapisywana.

## Testy i materiały dokumentacyjne

- Test 1: dodanie 1 kg złota w cenie PLN/kg daje prawidłową wartość zakupu.
- Test 2: cena PLN/kg i jej równowartość PLN/oz dają porównywalny wynik.
- Test 3: mieszane jednostki, np. 0,5 kg srebra i cena PLN/oz.
- Test 4: po ręcznej zmianie kursu złota zmienia się wartość portfela.
- Test 5: dodawanie i usuwanie transakcji nadal działa.

Po sprawdzeniu funkcji zachowaj screeny: `M03_portfel_v0.3.png`, `M04_formularz_kg.png`, `M05_kursy_v0.3.png`, `M06_edytowanie_kursu.png`. W dokumentacji podpisz je jako rzeczywiste screenshoty uruchomionej aplikacji (po wykonaniu, nie wcześniej).

## Ograniczenia

- Dane transakcji i ręcznie zmienione ceny są przechowywane tylko w pamięci aplikacji; po restarcie wracają dane przykładowe.
- Realne pobieranie kursów przez API to potencjalny kolejny etap; nie wolno umieszczać prywatnego klucza GoldAPI w kodzie aplikacji mobilnej ani w publicznym repozytorium.
- Dane spot nie odpowiadają automatycznie cenom sprzedaży detalicznej metali.
