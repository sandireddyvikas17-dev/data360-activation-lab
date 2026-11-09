# Build Log — Data 360 Unified Profile & Activation Lab

Personal portfolio build for the fictional brand VitalRoute Wellness. Not employer work.

## Day 1 — 2026-11-09 — Ingest & unify

**Built:**
- `README.md` — fictional brand framing, the three-systems problem, target architecture, repo principles
- `data-model/dlo-dmo-mapping.md` — DLO/DMO mapping sheets for all 3 sources (web store, mobile app, email list), with normalisation and null-handling notes
- `samples/` — clearly fictional source files:
  - `web-store-customers.csv` (5 customers), `web-store-orders.csv` (6 orders)
  - `mobile-app-users.json` (3 app users)
  - `email-list-subscribers.csv` (6 subscribers)
  - Sample records are designed to exercise the rules: an email match across all 3 sources (Ana Sharma), a phone+last-name match with different emails (Marcus Lee), a shared-inbox flag, a single-source profile (Tara Kim), and an unsubscribe that must win at the unified level (Sofia Reyes)
- `identity/identity-resolution-rules.md` — match keys in priority order, rules deliberately not used and why, per-field survivorship, conflict/review handling, worked examples from the sample data
- `consent/consent-model.md` — per-channel consent on the Unified Individual, merge rules (newest explicit wins; unsubscribe protected; unknown never activates), enforcement points for Days 2–3

**Next:** Day 2 — Calculated Insights (lifetime orders, days since last activity, engagement tier), segment definitions, and the SFMC-side mirror SQL.
