# Activated Data Extension Schema — VitalRoute Wellness (Day 3)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

## Scope

This schema is shared by the four sendable activated Data Extensions in
`activation-target-spec.md`:

- `VR_Lapsing_Activated`
- `VR_Lapsed_Activated`
- `VR_ActiveLoyal_Activated`
- `VR_NewSubscriber_Activated`

One shared schema, four separate DEs. The segment a row came from is
known from **which DE it is in**, never from a flag the Journey has to
remember to check.

All four DEs are **sendable**, with SubscriberKey as the send
relationship. The suppression DE (`VR_Suppression_Activated`) uses the
smaller schema at the end of this file and is **non-sendable**.

## Sendable activated DE — fields

| # | Field | SFMC type | Length / notes | Source (Data Cloud) | Purpose |
|---|---|---|---|---|---|
| 1 | `SubscriberKey` | Text | 100 — **Primary Key** | Unified Individual ID, resolved to the SFMC subscriber key for the primary Contact Point Email | Journey entry key; one row per person per DE |
| 2 | `UnifiedIndividualId` | Text | 100 — required | Unified Individual (Day 1) | Cross-system key: joins the SFMC send back to the Data Cloud profile for reporting and QA |
| 3 | `EmailAddress` | Email Address | — required | Primary Contact Point Email (survivorship winner, Day 1) | Send address; the app-verified email where one exists |
| 4 | `FirstName` | Text | 100, nullable | Individual — most complete value wins (Day 1 survivorship) | Personalisation, with a non-name fallback in the email build — a blank first name must never break a send |
| 5 | `SegmentName` | Text | 50 — required | Segment that produced the row (`Lapsing Subscriber`, etc.) | Audit and reporting; states in the row itself which definition admitted it |
| 6 | `EngagementTier` | Text | 30 — required | Insight 03 (`Active` / `Cooling` / `Lapsing` / `Lapsed` / `No recorded activity`) | Journey branching on the same label the segment filtered on |
| 7 | `DaysSinceLastActivity` | Number | Nullable — **NULL stays NULL** | Insight 02 | Journey branching / wait logic; NULL means "no recorded activity", never 0 |
| 8 | `LifetimeOrders` | Number | Required, default 0 | Insight 01 | Journey branching (e.g. repeat buyer vs. single purchase) |
| 9 | `LifetimeValue` | Decimal | 18,2 — nullable | Insight 01 | Reporting dimension only in this lab — not used to vary the offer, so value-based treatment differences never creep in unreviewed |
| 10 | `PlanStatus` | Text | 30, nullable | Engagement / app snapshot (`active` / `paused` / `cancelled`) | Journey exit / exclusion check — a plan cancelled after activation must still exit the win-back path |
| 11 | `EmailConsentStatus` | Text | 30 — required | Unified consent (Day 1 consent model) | Carried across so the state at activation is auditable; only `opted_in` rows are ever written to a sendable DE |
| 12 | `ConsentCapturedAt` | Date | Nullable | Unified consent (Day 1) | Audit: when the deciding consent event happened |
| 13 | `ActivatedAt` | Date | Required | Activation run timestamp | Freshness check — Journey entry rejects rows from a stale activation (see Journey design) |
| 14 | `ActivationRunId` | Text | 50 — required | Activation run identifier | QA / troubleshooting: every row in a run shares one ID, so a bad run can be identified and held as a unit |

### Schema rules

1. **No field is re-derived in SFMC.** Every insight field above is the
   Data Cloud value, carried across. If SFMC needs a value that is not
   here, the fix is a schema change here and in Data Cloud — not a
   Journey-side calculation that quietly becomes a second definition.
2. **NULL is preserved, especially for `DaysSinceLastActivity`.**
   Overwriting NULL with 0 at the DE would read as "active today" and
   would undo the Day 2 insight rule in the last metre of the pipeline.
3. **Consent fields are evidence, not the gate.** The gate already ran
   (`suppression-consent-check.sql`) before any row was written. These
   fields exist so a later question — "why was this person in this
   audience?" — can be answered from the row, not reconstructed.
4. **Retention:** activated DEs follow the daily activation overwrite.
   Rows are not accumulated run over run in the sendable DEs; run-level
   history for reporting lives in the reporting layer
   (`../reporting/dashboard-spec.md`), not in an ever-growing send DE.

## Suppression DE — `VR_Suppression_Activated` (non-sendable)

| # | Field | SFMC type | Notes |
|---|---|---|---|
| 1 | `SubscriberKey` | Text (100) — **Primary Key** | Same key as the sendable DEs, so exclusion is a direct key match |
| 2 | `UnifiedIndividualId` | Text (100) | Cross-system traceability |
| 3 | `EmailAddress` | Email Address | The suppressed contact point |
| 4 | `SuppressionReason` | Text (50) — required | Controlled values only: `unified_opt_out`, `hard_bounce`, `possible_shared_inbox`, `consent_unknown` |
| 5 | `SuppressedAt` | Date — required | When this suppression state was confirmed for this run |

A suppression row always carries a **reason**. "Excluded, reason
unknown" is not an acceptable state — it is the Day 1 / Project #1
suppression-first principle carried into Data Cloud activation: every
excluded contact must be lookup-able to the rule that excluded them.
