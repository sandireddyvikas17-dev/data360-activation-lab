# Data 360 Unified Profile & Activation Lab

**Builder:** Vikas Sandireddy — Salesforce Marketing Cloud / Data Cloud practitioner (7+ years overall, 5+ years hands-on SFMC; Data Cloud / Data 360, Marketing Cloud Intelligence, and Personalization hands-on since 2023)

**What this is:** A personal portfolio / practice build. Not employer work. No employer data, no employer systems, no real customer data.

**Demo brand:** *VitalRoute Wellness* — a fictional wellness-subscription brand. All names, emails, orders, and events in this repo are invented for this lab.

## The problem

VitalRoute sells the same subscription in three places, and each place keeps its own version of the customer:

1. **Web store** — knows orders and a checkout email, often typed in a hurry
2. **Mobile app** — knows device logins, plan usage, and a verified app email that may be different
3. **Email list** — knows who subscribed, who unsubscribed, and an email that may be neither of the above

Three systems, three versions of the same customer. The result is predictable:

- The same person gets counted twice (or three times) in audience sizes
- A subscriber who unsubscribed in email still gets activated from the app profile
- A lapsing subscriber is missed because their last activity lives in a system the segment never looked at
- Nobody can explain, for a given person, *why* two records were merged — or why they were not

This lab fixes the order: **ingest cleanly, resolve identity with explicit rules, honour consent at the unified-profile level, and only then build insights, segments, and activations.**

## The full flow — source to Journey

```
 SOURCE            INGEST & UNIFY (Day 1)        INSIGHTS (Day 2)
 ─────────────────  ───────────────────────────  ─────────────────────────────
 Web store (CSV) ─┐
 Mobile app (JSON)─┼─► Data Streams ─► DLOs ─► DMO mapping ─► Unified Individual
 Email list (CSV) ─┘                                            │
                                                     Identity resolution
                                                     (rules, precedence,     │
                                                      per-field survivorship) │
                                                     Consent on the unified  │
                                                      profile (per channel)  │
                                                                             ▼
                                              Calculated Insights, per Unified Individual:
                                              01 lifetime orders + value
                                              02 days since last activity (any source)
                                              03 engagement tier (Active / Cooling /
                                                  Lapsing / Lapsed / No recorded activity)

 SEGMENTS (Day 2)              ACTIVATION (Day 3)               JOURNEY & MEASURE (Day 3)
 ────────────────────────────  ──────────────────────────────   ────────────────────────────
 Lapsing Subscriber (61–90d)   Suppression / consent check ──►  VR_Lapsing_Activated
 Lapsed Subscriber (91d+)      re-run at activation, with       └─► Win-back Journey
 Active Loyal                   reasons for every hold-out          (entry gate re-checks
 New Subscriber — No Purchase                                       consent + suppression;
                                                                    goal = completed order)
        │                      Activation targets: one DE       Reporting (MCI-style spec):
        └─────────────────────► per segment + a non-sendable    funnel per stage, goal
                               suppression DE carrying a        conversions + click rate
                               reason per excluded contact      as headline — opens are
                                                                a diagnostic, never the
   SFMC mirror (Day 2): the same lapsing logic as                headline
   Automation Studio SQL, for Engagement-only
   audiences and parity QA — never a second
   entry source for the Journey above
```

- **DLO (Data Lake Object):** the ingested source data, as landed, in Data Cloud storage.
- **DMO (Data Model Object):** the harmonised model the DLO fields map to — e.g. `Individual`, `Contact Point Email`, `Sales Order`, `Engagement`.
- **Identity resolution:** the ruleset in `identity/identity-resolution-rules.md` decides when records from different sources become one Unified Individual, and which source wins each field (survivorship).
- **The three consent gates:** consent is checked at segment build (Day 2), again at activation (Day 3, `activation/suppression-consent-check.sql`), and again at Journey entry / send time in SFMC. No single gate is trusted on its own, because consent can change between any two of them.

## Build plan (3 days) — complete

| Day | Focus | Artefacts |
|---|---|---|
| **Day 1 — Ingest & unify** | Sources, DLO/DMO mapping, identity resolution, consent model | This README, `data-model/`, `samples/`, `identity/`, `consent/` |
| **Day 2 — Insights & segments** | Calculated Insights, segment definitions, SFMC-side mirror SQL | `insights/`, `segments/`, `sfmc-mirror/` |
| **Day 3 — Activate & measure** | Activation to SFMC, Journey entry, suppression check, reporting spec | `activation/`, `reporting/` |

## What the sample data proves (and does not)

The six fictional sample profiles are designed so every rule can be checked by hand — including the uncomfortable results:

- The one profile inside the lapsing window (Jordan Ellis, 87 days, 1 order) is **held out at activation** by the shared-inbox gate from Day 1's identity rules. The Lapsing activation correctly produces **0 sendable rows**. Zero, with a recorded reason, is this lab's headline Day 3 result — not a failure to be rounded up.
- Sofia Reyes, marketable in two source systems, is suppressed for email everywhere because her **unified** consent is `opted_out`.
- Priya Nair (Lapsed) and Ana Sharma (Active Loyal) activate normally — the gates are specific, not a blanket block.
- No performance rates are claimed from six fictional profiles. The reporting spec defines the metrics correctly so a live build would report them honestly.

## Repo layout

| Folder | Contents |
|---|---|
| `data-model/` | DLO/DMO mapping sheets for the 3 sources |
| `samples/` | Clearly fictional sample source files (CSV / JSON) |
| `identity/` | Identity-resolution ruleset: match keys, precedence, survivorship |
| `consent/` | Consent model: how consent is stored, merged, and enforced |
| `insights/` | Calculated Insights (Day 2): lifetime orders, days since last activity, engagement tier |
| `segments/` | Segment definitions with entry/exit rules (Day 2), incl. Lapsing Subscriber |
| `sfmc-mirror/` | Automation Studio SQL mirroring the lapsing segment for Engagement-only audiences (Day 2) |
| `activation/` | Activation target spec, activated DE schema, suppression/consent check query, Journey Builder entry design (Day 3) |
| `reporting/` | MCI-style dashboard spec: pipeline funnel, audience performance, consent & suppression page — and why opens are not the headline (Day 3) |
| `docs/` | Build log — one entry per day |

## Principles used throughout

1. **Rules before keys.** A match key (email, phone) is only as good as the rule around it — what counts as a match, what happens on conflict, and what is *not* merged and why. See `identity/identity-resolution-rules.md`.
2. **Consent lives on the unified profile, not in one source.** If any source says a person opted out of email, the unified profile does not activate them for email until a newer, explicit opt-in supersedes it. See `consent/consent-model.md`.
3. **Every merge must be explainable.** Each Unified Individual should be traceable back to its source records and the rule that linked them.
4. **No silent overwrites.** Survivorship is per-field and documented, not "last write wins for everything."
5. **A segment is not permission to send.** Membership is re-checked at activation and at Journey entry; every exclusion carries a lookup-able reason.
6. **Fictional data only.** Sample files use `example.com` / `.test` style addresses and invented names.

## Status

**Complete — all 3 days built.** See `docs/BUILD_LOG.md` for the per-day record. Project #1 (the SFMC campaign this lab's data layer complements) lives at github.com/sandireddyvikas17-dev/sfmc-campaign-portfolio.
