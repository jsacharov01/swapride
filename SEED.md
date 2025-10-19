# Firestore seed & rules

Tento projekt obsahuje ukázkové Firestore Security Rules a jednoduchý seed.

## Security Rules

Soubor `firestore.rules` je připraven pro nasazení do projektu Firebase:

- cars: veřejné čtení; create/update/delete jen vlastník (`ownerId == auth.uid`)
- swapRequests: čtení jen účastníci (from/to), vytvoření jen odesílatel; status smí měnit jen příjemce
- základní validace schématu (typy, rozsahy, neměnné klíče)

Nasazení (volitelné):

```zsh
# vyžaduje Firebase CLI a login (firebase login)
firebase deploy --only firestore:rules
```

## Seed

- `SeedService` se spustí při prvním startu aplikace (přes `onAppear` ve `swaprideApp.swift`).
- Pokud aktuální uživatel (mock) nemá v cloudu žádné auto, vloží se 1 demo auto.
- Ochranný příznak `UserDefaults.didSeedFirestore` zabrání opakovanému seedování.

Pozn.: V produkci seed nepoužívejte, slouží jen pro rychlé oživení dema.
