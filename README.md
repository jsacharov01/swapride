# swapride (MVP)

Aplikace pro výměnu aut mezi uživateli (SwiftUI + Firebase). Tento MVP běží na mock datech v paměti a umožňuje:

- Prohlížet dostupná auta ostatních uživatelů
- Přidat vlastní auto jako nabídku
- Odeslat žádost o výměnu (vybrat moje auto, datum od/do, zpráva)
- Spravovat příchozí a odeslané žádosti (přijmout/odmítnout)

## Jak spustit

1) Otevřete projekt v Xcode: `swapride.xcodeproj`
2) Ujistěte se, že je v targetu přidaný soubor `GoogleService-Info.plist` (v repu je příklad `GoogleService-Info.plist.example`).
3) V Xcode přidejte nové Swift soubory do targetu, pokud je Xcode nepřidal automaticky (Models, Views, ViewModels, AppState).
4) Zvolte iOS simulátor a Build & Run.

Pozn.: Firebase je inicializovaný (Analytics). Přihlášení a databáze nejsou zatím zapojené — data jsou v paměti.

## Struktura

- `swapride/swaprideApp.swift` – vstup do aplikace, `MainTabView` + `AppState` jako EnvironmentObject
- `swapride/Models` – datové modely `Car`, `SwapRequest`, `UserProfile`
- `swapride/AppState.swift` – jednoduché úložiště mock dat (+ metody pro žádosti)
- `swapride/Views` – `MainTabView`, `CarListView`, `CarDetailView`, `CreateListingView`, `RequestsView`, `ProfileView`
- `swapride/ViewModels` – `CreateListingViewModel`

## Další kroky (doporučení)

- Přihlášení (Sign in with Apple/Google) přes Firebase Auth, nahradit `currentUser` v `AppState`.
- Databáze: Firestore (kolekce `users`, `cars`, `swapRequests`), realtime synchronizace, bezpečnostní pravidla.
- Obrázky aut: Firebase Storage + image picker (PhotoLibrary), generování náhledů.
- Dostupnost v kalendáři, filtrování podle lokality, počtu míst atd.
- Notifikace (Cloud Messaging) pro nové žádosti a změny stavu.
- Chat k žádosti (volitelné).
- Ověření řidičáku, depozita/pojištění, hodnocení a recenze.

## Poznámky

- Nové soubory je třeba přidat do targetu v Xcode (Build Phases → Compile Sources), pokud je Xcode nepřidal automaticky.
- Minimální verze iOS a ostatní nastavení řeší `swapride.xcodeproj`. Pokud budete měnit strukturu složek, upravte i projekt.
