# quote-engine-svc

A small public TypeScript service that computes insurance quotes. It exists as a
reference workload for secure-SDLC governance evidence: branch protection,
required reviews, CI, SAST (CodeQL), SCA (dependency review), and secret
scanning all run against this repo and are read as compliance evidence.

## API

- `GET /health` → `{ "status": "ok" }`
- `POST /quote` → computes a premium from a `QuoteRequest`

```jsonc
// POST /quote
{
  "driverAge": 40,
  "yearsClaimFree": 5,
  "vehicleCategory": "suv",      // compact | sedan | suv | sports
  "coverageTier": "premium",     // basic | standard | premium
  "loyaltyYears": 6              // optional
}
```

The response includes a `lineItems` audit trail naming every surcharge and
discount that moved the final premium.

## Development

```bash
npm ci
npm run lint
npm test          # jest, with coverage thresholds enforced
npm run build     # tsc -> dist/
npm start
```

## Domain

- `rating.ts` — base premium (tier × vehicle category) and age-risk surcharge.
- `discount.ts` — no-claims discount and the bracketed loyalty discount.
- `quote.ts` — composes the modules and enforces the regulatory premium floor.
