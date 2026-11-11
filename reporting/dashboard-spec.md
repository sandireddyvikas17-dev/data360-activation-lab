# Reporting Spec — MCI-Style Dashboard (Day 3)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

## What this dashboard is for

The reporting layer for the full lab flow: source → unified profile →
insights → segment → activation → Journey. It is written as a
Marketing Cloud Intelligence (MCI / Datorama)-style spec — harmonised
dimensions and named metrics that can be built the same way in MCI —
because the questions it answers cross systems: no single tool in the
flow (Data Cloud, SFMC, the web store) can answer them alone.

The dashboard's job is not to make the program look good. Its job is
to make each stage of the pipeline **accountable**: every stage reports
the count it received, the count it passed on, and the difference with
reasons.

## The headline rule: opens are not the headline

**The headline metric is completed orders from activated audiences
(win-back goal conversions), reported with click rate as the headline
engagement metric.**

Email opens are on this dashboard — as a **diagnostic**, in the
deliverability section, never as the headline, for three plain reasons:

1. **Opens are not measured the same way everywhere.** Image-proxy and
   privacy features in major mail clients pre-fetch images, recording
   "opens" no person made. An open rate can rise because a client
   changed its proxy behaviour, with no change in human behaviour at
   all — a headline that can move for reasons unrelated to the work
   is not a headline.
2. **Opens do not branch anything in this lab.** The Journey design
   (`../activation/journey-builder-entry-design.md`) deliberately
   never uses opens as a decision signal. Reporting as the headline a
   signal the program itself does not trust enough to act on would be
   incoherent.
3. **The business question is orders and recoveries, not pixel loads.**
   The lapsing program exists to bring back paying subscribers.
   Clicks are the closest honest engagement proxy for intent; orders
   are the outcome. Opens are neither.

This is the same reporting position as Project #1 (click rate as the
headline engagement metric), applied to the Data Cloud flow.

## Page 1 — Pipeline funnel (is the flow itself healthy?)

One row per stage, per day. A break in this table is a pipeline
problem, not a marketing result, and is investigated before any
performance number on Page 2 is discussed.

| Stage | Metric | Definition |
|---|---|---|
| Sources | Source records ingested | Rows landed per source (web store / app / email list) |
| Identity | Unified Individuals | Profiles after identity resolution; plus merges and `possible_shared_inbox` flags raised that day |
| Insights | Profiles with a tier | Unified Individuals with a non-NULL `Engagement_Tier`; NULL-tier count shown separately — it is a real population, not an error to hide |
| Segments | Members per segment | Per Day 2 segment, after segment-build gates |
| Activation | Members / held out / sendable | The three QA counts from `suppression-consent-check.sql` Query 2 — **always shown together**, with held-out broken down by `SuppressionReason` |
| Journey | Entries / goal conversions / exits by reason | Entries from the activated DE only; exits grouped by the Journey exit table's reasons |

## Page 2 — Audience performance (did activation produce outcomes?)

**Grain:** one row per activation run × segment. Populations are never
blended across segments — Lapsing performance averaged into Lapsed
performance would hide exactly the difference the segment windows
exist to create.

| Metric | Definition | Notes |
|---|---|---|
| Goal conversions (headline) | Completed orders by activated members during the Journey window | The win-back outcome; attributed to the activation run that entered the member |
| Click rate (headline engagement) | Unique clicks ÷ delivered | Headline engagement metric — see the opens rule above |
| Delivered / bounces | Sends, delivered, hard/soft bounces per run | Hard-bounce rate is also a data-quality signal for the contact-point survivorship |
| Unsubscribes / complaints | Per run and per segment | A win-back that produces unsubscribes faster than orders is a harm, reported as one |
| Recovery rate | Goal conversions ÷ Journey entries | Read alongside the natural-recovery check below — the Journey does not get credit for people who would have returned anyway without a comparison |
| Revenue (reporting only) | Sum of completed-order amounts for goal conversions, from sample-schema `Total_Amount` in a live build | Reported, never used in this lab to vary treatment inside the Journey |

**Dimensions (harmonised across Data Cloud + SFMC + orders):**
`ActivationRunId`, `SegmentName`, `EngagementTier`,
`DaysSinceLastActivity` (banded: 61–70 / 71–80 / 81–90 for the lapsing
audience), `LifetimeOrders` (1 / 2+), `PlanStatus`, send date,
Journey version. The join key across systems is
`UnifiedIndividualId` ↔ `SubscriberKey`, carried on the activated DE
for exactly this purpose (`../activation/activated-data-extension-schema.md`).

## Page 3 — Consent & suppression (the honesty page)

| Metric | Definition |
|---|---|
| Held-out count by reason | Per activation run: `unified_opt_out`, `hard_bounce`, `possible_shared_inbox`, `consent_unknown` |
| Suppression audience size | Total rows in `VR_Suppression_Activated`, trended daily |
| Zero-sendable runs | Count of runs where sendable = 0, **split by cause**: empty segment vs. all members held out — these are different facts and are never merged into one "zero" |
| Consent changes per day | Unified consent state changes by channel — a spike after a send is a signal about that send, reported next to it |

This page is reviewed with the same standing as Page 2. A program can
only claim its consent model works if the held-out numbers are visible
and boring — small, explained, and with reasons that sum to the total.

## Diagnostics (where opens actually live)

Open rate, device/client breakdown, send-time performance, and link-level
click detail sit here, labelled diagnostic. They are used to debug a
specific send (rendering, placement, a broken link) — never rolled up
as program success, never used to branch a Journey, and never compared
across a mail-client privacy change as if the comparison were clean.

## Sample-data expectations (fictional, for build QA only)

Against the Day 1 samples, a correct first build shows: Lapsing funnel
1 member → 1 held out (`possible_shared_inbox`) → 0 sendable →
0 Journey entries → 0 conversions, with the zero explained at every
stage by the stage above it; Lapsed funnel 1 → 0 → 1 (Priya Nair);
Active Loyal 1 → 0 → 1 (Ana Sharma); suppression audience carrying
Sofia Reyes with `unified_opt_out`. No performance rates are computed
from the sample data — six fictional profiles cannot support a rate,
and this spec does not pretend otherwise. Rates exist to be defined
correctly here so a live build reports them honestly later.

## Cadence & ownership of the numbers

- Pipeline page: daily, reviewed with the activation run.
- Performance page: per activation run, with a weekly roll-up that
  keeps segment grain.
- Consent page: daily — a consent anomaly is same-day work, not a
  weekly discovery.
- Any definition change (a tier threshold, a segment window, the goal)
  is versioned in this spec and in the upstream artefact that owns it.
  Reports never silently restate history under a new definition.
