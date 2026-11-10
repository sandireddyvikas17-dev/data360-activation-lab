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

## Day 2 — 2026-11-10 — Insights & segments

**Built:**
- `insights/README.md` — the framing ("a calculated insight is just a business question written in SQL"), grain/refresh rules, and the shared rules (completed orders only; activity = any source; no activity stays NULL)
- `insights/01-lifetime-orders.sql` — Calculated Insight: lifetime completed orders + value + first/last order date per Unified Individual, with a hand-checked worked table against the sample orders
- `insights/02-days-since-last-activity.sql` — Calculated Insight: latest activity across orders + engagement (the Day 1 survivorship rule as SQL), days-since with explicit NULL handling; worked table evaluated 2026-11-10 (Ana 5, Marcus 13, Sofia 39, Jordan 87, Priya 303, Tara NULL)
- `insights/03-engagement-tier.sql` — Calculated Insight layered over Insights 01–02: Active ≤30 / Cooling 31–60 / Lapsing 61–90 / Lapsed 91+ / No recorded activity; sample data lands in five different tiers
- `segments/segment-definitions.md` — four segments with entry/exit rules and the universal consent gates: **Lapsing Subscriber** (61–90 days, ≥1 order, not cancelled — sample check: Jordan Ellis qualifies on activity but is held out by the shared-inbox gate, so zero sendable members is the correct result), Lapsed Subscriber, Active Loyal, New Subscriber — No Purchase Yet
- `sfmc-mirror/automation-studio-lapsing-mirror.sql` + `sfmc-mirror/README.md` — the same lapsing logic as an Automation Studio T-SQL query over SFMC Data Extensions for Engagement-only audiences, with its limits stated plainly (SubscriberKey vs Unified Individual, SFMC-side consent only, sync-dependent activity) and QA parity checks

**Next:** Day 3 — activation target spec + activated DE schema, Journey Builder entry design, suppression/consent check, MCI-style reporting spec, and the wrap-up.
