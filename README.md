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

## Build plan (3 days)

| Day | Focus | Artefacts |
|---|---|---|
| **Day 1 — Ingest & unify** | Sources, DLO/DMO mapping, identity resolution, consent model | This README, `data-model/`, `samples/`, `identity/`, `consent/` |
| Day 2 — Insights & segments | Calculated Insights, segment definitions, SFMC-side mirror SQL | `insights/`, `segments/` |
| Day 3 — Activate & measure | Activation to SFMC, Journey entry, suppression check, reporting spec | `activation/`, `reporting/` |

## Architecture (target state)

```
Web store (CSV) ──┐
Mobile app (JSON) ─┼─► Data Streams ─► DLOs ─► DMO mapping ─► Unified Individual
Email list (CSV) ──┘                                          │
                                                              ├─► Consent check (unified)
                                                              ├─► Calculated Insights (Day 2)
                                                              ├─► Segments (Day 2)
                                                              └─► Activation ─► SFMC Data Extension ─► Journey (Day 3)
```

- **DLO (Data Lake Object):** the ingested source data, as landed, in Data Cloud storage.
- **DMO (Data Model Object):** the harmonised model the DLO fields map to — e.g. `Individual`, `Contact Point Email`, `Sales Order`, `Engagement`.
- **Identity resolution:** the ruleset in `identity/identity-resolution-rules.md` decides when records from different sources become one Unified Individual, and which source wins each field (survivorship).

## Repo layout

| Folder | Contents |
|---|---|
| `data-model/` | DLO/DMO mapping sheets for the 3 sources |
| `samples/` | Clearly fictional sample source files (CSV / JSON) |
| `identity/` | Identity-resolution ruleset: match keys, precedence, survivorship |
| `consent/` | Consent model: how consent is stored, merged, and enforced |
| `docs/` | Build log — one entry per day |

## Principles used throughout

1. **Rules before keys.** A match key (email, phone) is only as good as the rule around it — what counts as a match, what happens on conflict, and what is *not* merged and why. See `identity/identity-resolution-rules.md`.
2. **Consent lives on the unified profile, not in one source.** If any source says a person opted out of email, the unified profile does not activate them for email until a newer, explicit opt-in supersedes it. See `consent/consent-model.md`.
3. **Every merge must be explainable.** Each Unified Individual should be traceable back to its source records and the rule that linked them.
4. **No silent overwrites.** Survivorship is per-field and documented, not "last write wins for everything."
5. **Fictional data only.** Sample files use `example.com` / `.test` style addresses and invented names.

## Status

Day 1 — see `docs/BUILD_LOG.md`.
