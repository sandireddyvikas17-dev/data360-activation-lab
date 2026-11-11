# Segment Definitions — VitalRoute Wellness (Day 2)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

Segments are built in Data Cloud on the **Unified Individual**, filtered on
the Calculated Insight fields from `../insights/`. Every segment below states
the same four things: **purpose, entry rules, exit rules, and the gate checks
that run before anyone in it can be activated.**

## Gates that apply to EVERY email segment

These are not per-segment choices — they are the Day 1 consent model
(`../consent/consent-model.md`) enforced at segment build:

1. **Email consent = `opted_in`** on the unified profile. `unknown` never
   activates; absence of an opt-out is not an opt-in.
2. **Not `bounced_hard`** on the primary contact point.
3. **Not flagged `possible_shared_inbox`** (Day 1 identity review flag) —
   held out until the merge question is resolved, because sending one
   person's win-back to a shared household inbox is a wrong-merge harm.
4. Consent is **re-checked at activation** (Day 3) and again at send time in
   SFMC — membership in a segment is never itself permission to send.

Refresh cadence for all segments: **daily**, aligned to the insight refresh.
"Entry" below means: the profile first meets all entry rules on a daily
refresh and was not a member after the previous refresh. "Exit" means: it no
longer meets them on a later refresh (or is removed by a gate).

---

## 1. Lapsing Subscriber — the headline segment

**Purpose:** catch a paying subscriber while the relationship is going
quiet but is still recoverable, and feed the Day 3 win-back journey.
Intervening at day 61–90 is the point of the whole lab: earlier is nagging,
later is archaeology.

**Entry rules — ALL must be true:**

| # | Rule | Field / source |
|---|---|---|
| 1 | Days since last activity is **between 61 and 90 inclusive** | `Days_Since_Last_Activity__c` (Insight 02) |
| 2 | Engagement tier = **Lapsing** | `Engagement_Tier__c` (Insight 03 — same window, stated as the label so reports and the segment can never drift apart) |
| 3 | **Lifetime orders ≥ 1** — they have actually bought before; a never-buyer going quiet is a different problem with a different message | `Lifetime_Orders__c` (Insight 01) |
| 4 | Plan status is **not `cancelled`** — a cancelled plan is a churn workflow, not a lapsing one | Engagement / app plan status |
| 5 | All four universal gates above pass (email `opted_in`, not bounced, not shared-inbox-flagged) | Consent model |

**Why a window (61–90), not just "61+":** a profile that crosses day 91 has
changed state — it is *lapsed*, and it gets the lapsed segment's treatment
(different offer posture, different cadence, lower send frequency). A
"61+" segment would silently keep both populations mixed forever.

**Exit rules — ANY one removes the profile at the next daily refresh:**

| Exit trigger | Why |
|---|---|
| Any new activity (order, app activity, email engagement) drops days-since below 61 | The insight recalculates, the premise is gone — they came back on their own; the win-back journey must stop, not send into a recovery it didn't cause |
| Days-since passes 90 with no activity | Graduates to **Lapsed Subscriber** (Segment 2) — handed off, not dropped |
| Email consent changes to `opted_out` or contact point goes `bounced_hard` | Gate failure — removed immediately at next refresh and written to suppression (Day 3) |
| Plan status becomes `cancelled` | Moves to the churn path, out of win-back |
| Profile is merged or split by a later identity-resolution run | Re-evaluated as the new unified profile — membership never survives a merge on the old ID alone |

**Sample-data check (evaluated 2026-11-10):**

- **Jordan Ellis — 87 days, 1 order → meets entry rules 1–4**, but his
  checkout email is the flagged shared inbox (`household.shared@example.com`,
  Day 1 worked example 3), so **gate 3 holds him out pending review**. The
  segment working correctly produces *zero sendable members* from the sample
  data today — and that is the correct result, not a failure: the gates are
  doing the job they exist for.
- **Priya Nair — 303 days** → not lapsing; she is in Lapsed (Segment 2).
- **Sofia Reyes — 39 days** → only Cooling; and her unified email consent is
  `opted_out` (Day 1), so no email segment may contain her at any tier.

---

## 2. Lapsed Subscriber

**Purpose:** long-quiet former buyers, for a low-frequency reactivation
attempt with an honest "it's been a while" posture — separate segment so its
performance is never averaged into the lapsing win-back numbers.

- **Entry:** days-since **≥ 91** AND lifetime orders ≥ 1 AND tier = `Lapsed`
  AND plan not `cancelled` AND all universal gates pass.
- **Exit:** any new activity (re-enters the normal tier ladder);
  consent/bounce gate failure; plan cancellation; 180 days in-segment with
  no engagement → moved to a dormant/suppression review list rather than
  being re-mailed indefinitely.
- **Sample check:** Priya Nair (303 days, 1 order, `opted_in`) is the member.

## 3. Active Loyal

**Purpose:** recent, repeat buyers — the audience for early access,
referral, and plan-upgrade messages, and the exclusion baseline you never
want win-back creative leaking into.

- **Entry:** tier = `Active` (days-since ≤ 30) AND lifetime orders ≥ 2 AND
  all universal gates pass.
- **Exit:** days-since passes 30, or any gate failure.
- **Sample check:** Ana Sharma (5 days, 2 orders, annual plan) is the member.

## 4. New Subscriber — No Purchase Yet

**Purpose:** email subscribers inside their first 30 days who have never
bought — an onboarding/education audience, explicitly separated from
lapsing logic (they have no activity pattern to lapse *from*).

- **Entry:** first-seen date within the last 30 days AND lifetime orders = 0
  AND days-since is `NULL` or ≤ 30 AND all universal gates pass.
- **Exit:** first purchase (moves to the buyer ladder); day 31 arrives with
  no purchase (graduates out — staying "new" forever is how onboarding
  journeys become spam); any gate failure.
- **Sample check:** no sample profile qualifies on 2026-11-10 — Tara Kim is
  the shape of this profile (email-only, 0 orders) but her first-seen date
  is 2026-02-10, so she correctly aged out months ago. An empty segment with
  a documented reason is a valid QA result.

---

## How these segments are used on Day 3

Each segment activates to SFMC as its own Data Extension (Day 3 spec), with
the insight fields carried across (`Engagement_Tier`, `Days_Since_Last_Activity`,
`Lifetime_Orders`) so the Journey can branch on the same values the segment
was built from — and the suppression/consent check runs again at activation,
because consent can change between segment build and send.
