# Activation Target Spec — VitalRoute Wellness (Day 3)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

## What activation means in this lab

Activation is the step where a Data Cloud segment stops being an analysis
and becomes a sendable audience in Salesforce Marketing Cloud (SFMC).
It is also the step where Data Cloud projects quietly fail — not because
the segment logic was wrong, but because consent, suppression, and field
mapping were treated as someone else's problem at the handoff.

This spec is written so that failure cannot happen silently here.

## Activation targets

| # | Data Cloud segment (Day 2) | Activation target in SFMC | Sendable? | Used by |
|---|---|---|---|---|
| 1 | **Lapsing Subscriber** | Data Extension `VR_Lapsing_Activated` | Yes — sendable DE | Win-back Journey (see `journey-builder-entry-design.md`) |
| 2 | Lapsed Subscriber | Data Extension `VR_Lapsed_Activated` | Yes — sendable DE | Separate low-frequency reactivation Journey (design only in this lab) |
| 3 | Active Loyal | Data Extension `VR_ActiveLoyal_Activated` | Yes — sendable DE | Early-access / referral sends (design only in this lab) |
| 4 | New Subscriber — No Purchase Yet | Data Extension `VR_NewSubscriber_Activated` | Yes — sendable DE | Onboarding Journey (design only in this lab) |
| — | Suppression audience (not a segment) | Data Extension `VR_Suppression_Activated` | **No — non-sendable, exclusion only** | Every Journey above, as an exclusion / entry gate |

One segment, one activated DE. Segments are never merged into a single
"activated audience" DE with a type flag doing the separation in the
Journey — merged audiences are how a lapsing win-back creative ends up
in front of an Active Loyal member, and how reporting can no longer tell
the populations apart.

## Activation settings (per target)

| Setting | Value in this lab | Why |
|---|---|---|
| Activation type | Data Cloud Activation to Marketing Cloud (Engagement) | The audiences are consumed by SFMC Journeys, not by an external ad platform |
| Membership refresh | Daily, after the Calculated Insight + segment refresh | An activation fresher than its insights is impossible; an activation older than its segment is a stale audience |
| Consent re-check at activation | **Required** — see `suppression-consent-check.sql` | Consent can change between segment build (Day 2) and activation (Day 3); segment membership is never itself permission to send |
| Identity carried across | Unified Individual ID **and** the SFMC SubscriberKey resolved from the primary Contact Point Email | The Journey keys on SubscriberKey; reporting and QA key on Unified Individual ID — both must survive the handoff or the two sides can never be reconciled |
| Fields carried across | The full schema in `activated-data-extension-schema.md` — including the insight fields the segment was built from | The Journey branches on the same values the segment filtered on; re-deriving them in SFMC would create a second, drifting definition of "lapsing" |
| Deduplication | One row per Unified Individual per activation run; duplicate Unified IDs fail the run's QA count, they are not silently de-duplicated | A duplicate here is an identity-resolution symptom (Day 1), not a formatting problem |
| Suppression handling | Suppression audience is activated **before** the sendable audiences in the same run, and every Journey checks it at entry | Order matters: a sendable audience refreshed before its suppression audience is, for that window, unsuppressed |

## Run order (daily)

1. Data Streams refresh (sources → DLOs → DMOs)
2. Identity resolution re-run (Day 1 ruleset)
3. Calculated Insights refresh (Day 2, Insights 01–03)
4. Segment refresh (Day 2 definitions, universal gates applied)
5. **Suppression / consent check** (`suppression-consent-check.sql`) —
   produces the suppression audience and the held-out count for this run
6. Activation of the suppression DE
7. Activation of the four sendable DEs
8. Journey entry evaluation in SFMC (Journeys read the activated DEs;
   they do not re-run segment logic)

If any step fails, later steps do not run on partial data. In particular,
a failed suppression check means **no activation that day** — the previous
day's audiences stand, and the failure is visible, rather than a fresh
audience going out unchecked.

## Sample-data check (evaluated 2026-11-11, against the Day 1 samples)

- **Lapsing Subscriber → `VR_Lapsing_Activated`: 0 rows.**
  Jordan Ellis (87 days, 1 lifetime order) meets the activity rules but
  is held out by the `possible_shared_inbox` gate. Zero is the correct,
  expected result — the same result the Day 2 segment check produced,
  now confirmed again at the activation gate.
- **Lapsed Subscriber → `VR_Lapsed_Activated`: 1 row** — Priya Nair
  (303 days, 1 order, email `opted_in`).
- **Active Loyal → `VR_ActiveLoyal_Activated`: 1 row** — Ana Sharma
  (5 days, 2 orders, email `opted_in`).
- **Suppression audience: includes Sofia Reyes** — unified email consent
  is `opted_out` (Day 1 worked example), with reason `unified_opt_out`.
  She appears in no sendable DE at any tier, however marketable her
  web-store and app profiles look on their own.

An activation run that produced a lapsing audience of 1 by quietly
dropping the shared-inbox gate would look more successful and be wrong.
This lab treats the held-out count as a result to report, not a problem
to hide.

## What activation does NOT do

- It does not fix identity. A duplicate or a wrong merge discovered at
  activation goes back to the Day 1 ruleset — it is never patched in
  the activated DE by hand.
- It does not grant consent. `unknown` consent stays un-activated for
  email (Day 1 consent model, Rule 4), however large the segment is.
- It does not override an SFMC-side unsubscribe that happens after
  activation. That last check lives at Journey entry and at send time
  in SFMC (see the Journey design) — activation is one gate of three,
  not the only gate.
