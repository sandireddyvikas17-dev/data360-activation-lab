# Calculated Insights — VitalRoute Wellness (Day 2)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

## The idea in one line

> **A calculated insight is just a business question written in SQL.**

Every insight in this folder started as a question a marketer actually asked,
in plain English. The SQL is the translation — nothing more:

| Business question | Calculated Insight | File |
|---|---|---|
| "How much has this person actually bought from us, ever?" | Lifetime orders + lifetime value | `01-lifetime-orders.sql` |
| "How long has it been since this person did *anything* with us?" | Days since last activity | `02-days-since-last-activity.sql` |
| "Is this person active, cooling off, lapsing, or gone?" | Engagement tier | `03-engagement-tier.sql` |

## How Calculated Insights work here

- **Grain:** one row per **Unified Individual** (the profile built on Day 1 in
  `identity/identity-resolution-rules.md`). Insights never read a single
  source system — an insight built on the web store alone would miss app
  activity, which is exactly the bug this lab exists to prevent.
- **Inputs:** the harmonised DMOs from `data-model/dlo-dmo-mapping.md` —
  `Individual`, `Sales Order`, and `Engagement`. In a live Data Cloud org
  these are the `ssot__*__dlm` API objects; the logical names are used here
  so the SQL stays readable.
- **Output:** each insight lands back on the Unified Individual as a named
  field a segment can filter on (see `../segments/segment-definitions.md`).
  A segment should be a simple filter over insight fields — if a segment
  needs its own complex SQL, the insight underneath it is probably missing.
- **Refresh:** insights recalculate on the Data Stream refresh cadence
  (daily batch in this lab's design). Segment membership is therefore only
  ever as fresh as the last refresh — entry/exit rules in the segment doc
  are written with that daily grain in mind.
- **Consent is not an insight.** Consent is a state on the unified profile
  (`../consent/consent-model.md`) and is applied as a gate in segments and
  again at activation — never baked into an engagement calculation. A person
  can be "lapsing" as a fact and still be un-sendable. Both things are true,
  and the model keeps them separate on purpose.

## Shared rules across all three insights

1. **Completed orders only.** `refunded` and `cancelled` orders never count
   toward lifetime orders or value.
2. **Activity means any activity.** Orders, app activity, and email
   engagement all count, wherever they happened (Day 1 survivorship rule:
   last activity = latest timestamp across *all* sources).
3. **No activity is a value, not an error.** A unified profile with no
   orders and no engagement gets `NULL` / `No recorded activity`, not `0` —
   `0 days since last activity` would falsely read as "active today."
