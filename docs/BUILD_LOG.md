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

## Day 3 — 2026-11-11 — Activate & measure (final day)

**Built:**
- `activation/README.md` — the Day 3 framing ("activation is where Data Cloud projects quietly fail") and the file map for the handoff
- `activation/activation-target-spec.md` — one activated DE per segment (`VR_Lapsing_Activated`, `VR_Lapsed_Activated`, `VR_ActiveLoyal_Activated`, `VR_NewSubscriber_Activated`) plus the non-sendable suppression DE; daily run order (streams → identity → insights → segments → suppression check → suppression DE → sendable DEs → Journey entry); a failed suppression check means no activation that day. Sample check: Lapsing 0 rows (Jordan Ellis held out, shared-inbox gate), Lapsed 1 (Priya Nair), Active Loyal 1 (Ana Sharma), suppression carrying Sofia Reyes (`unified_opt_out`)
- `activation/activated-data-extension-schema.md` — shared sendable-DE schema (SubscriberKey PK, UnifiedIndividualId, insight fields carried across un-re-derived, consent status + timestamp as audit evidence, NULL days-since preserved as NULL) and the suppression DE schema with a controlled `SuppressionReason`
- `activation/suppression-consent-check.sql` — the Day 2 universal gates re-run at activation against current unified consent: Query 1 produces the suppression set with one reason per held-out profile (`unified_opt_out` / `hard_bounce` / `possible_shared_inbox` / `consent_unknown`, in that precedence); Query 2 produces the members / held-out / sendable QA counts (Lapsing sample: 1 / 1 / 0 — zero sendable is the correct result)
- `activation/journey-builder-entry-design.md` — win-back Journey consuming `VR_Lapsing_Activated` only: five-check entry gate (incl. SFMC-side unsubscribe still winning at entry/send), LifetimeOrders split, recovery exits that stop the Journey sending into a recovery it did not cause, goal = completed order, no opens-based branching, no entry from the SFMC mirror DE; expected sample entry count stated in advance: zero, with the reason traceable
- `reporting/dashboard-spec.md` — MCI-style reporting spec in three pages (pipeline funnel per stage; audience performance per activation run × segment; consent & suppression honesty page), harmonised dimensions joined on UnifiedIndividualId ↔ SubscriberKey, and the headline rule: goal conversions + click rate are the headline — opens are a diagnostic only (proxy pre-fetching, no Journey ever branches on them, and they do not answer the business question)
- `README.md` — final version tying the full flow together (source → unified profile → insights → segment → activation → Journey) with a full-flow diagram, the three consent gates, and the sample-data results stated plainly

**Project #2 complete.** Finishing pipeline (same as Project #1): repo live on GitHub, Projects entry added to the master resume next to Project #1 with the GitHub link, project added to LinkedIn Projects, and a wrap-up LinkedIn post with a fresh post-build screenshot.
