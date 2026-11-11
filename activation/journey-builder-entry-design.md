# Journey Builder Entry Design — Lapsing Win-Back (Day 3)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

## Which Journey this is

The headline Journey of the lab: the **win-back Journey fed by the
Lapsing Subscriber activation** (`VR_Lapsing_Activated`). The other
three activated audiences (Lapsed, Active Loyal, New Subscriber) follow
the same entry pattern with their own Journeys; they are not designed
in full here, and this Journey never accepts their DEs as an entry
source.

## Entry source

| Setting | Value |
|---|---|
| Entry type | Data Extension entry — `VR_Lapsing_Activated` (schema: `activated-data-extension-schema.md`) |
| Entry key | `SubscriberKey` |
| Schedule | Daily, **after** the activation run in `activation-target-spec.md` completes (insights → segments → suppression check → suppression DE → sendable DEs → Journey entry, in that order) |
| Re-entry | No re-entry while the contact is in the Journey; re-entry after exit only on a **new** activation run with a new `ActivationRunId` where the profile again meets the segment rules — finishing the Journey never by itself makes someone lapsing again |
| Entry filter (all must pass, evaluated on the activated row) | See the entry gate below |

## The entry gate — checked in the Journey, not assumed from the DE

Being in the activated DE is necessary, not sufficient. At entry, the
Journey re-checks:

1. **`EmailConsentStatus = opted_in`** on the activated row.
2. **Not present in `VR_Suppression_Activated`** (key match on
   `SubscriberKey`) — this is the check that catches a consent change
   recorded on the unified profile after segment build.
3. **SFMC-side subscriber status is still Active** — an unsubscribe or
   hard bounce that happened in SFMC *after* activation wins at entry
   and at send time. This is the third consent gate (segment build →
   activation → SFMC entry/send), and it exists because no single
   system's view of consent is complete on its own.
4. **`PlanStatus` is not `cancelled`** — a cancellation after activation
   moves the person to the churn path; the win-back Journey must not
   send into it.
5. **`ActivatedAt` is from the current run** — a stale row left by a
   failed or skipped activation never enters. A missed day produces
   no entry that day, not entry off yesterday's audience presented as
   today's.

A contact who fails any check does not enter, and the failed check is
the logged reason — same suppression-with-a-reason principle as the
activation spec.

## Journey flow (design)

```
Entry: VR_Lapsing_Activated (daily, post-activation)
  │
  ├─ Entry gate (5 checks above) ── fail ─► Exit, reason logged
  │
  ├─ Decision split: LifetimeOrders
  │     ├─ ≥ 2 orders ─► Win-back Email 1A — "we miss you" for a repeat
  │     │                 buyer; references plan/value they already have
  │     └─ = 1 order  ─► Win-back Email 1B — same ask, first-purchase
  │                       framing; no repeat-buyer claims the data
  │                       does not support
  │
  ├─ Wait 4 days ─► Engagement check (Data Extension / engagement split)
  │     ├─ Any new activity recorded (order / app / email engagement
  │     │  refreshed into the profile) ─► Exit — goal met / recovered.
  │     │  The Journey stops; it does not send into a recovery it did
  │     │  not cause and then claim it.
  │     └─ No activity ─► Win-back Email 2 — one reminder, plainer
  │                        subject posture, preference-centre link
  │                        offered (pause is a valid outcome)
  │
  ├─ Wait 7 days ─► Final engagement check
  │     ├─ Activity ─► Exit — recovered
  │     └─ No activity ─► Exit — no third win-back email.
  │                        The profile will be re-evaluated by the
  │                        segment on later daily runs: past day 90 it
  │                        belongs to Lapsed Subscriber, with that
  │                        segment's lower-frequency treatment — it is
  │                        not kept in win-back indefinitely.
  │
  └─ Goal: any completed order during the Journey window
     (evaluated from the refreshed profile / order data, not from email
     opens — see ../reporting/dashboard-spec.md for why)
```

## Exit rules (any one exits, at the next evaluation)

| Exit trigger | Why |
|---|---|
| Completed order (goal) | The win-back worked or the person returned — either way, win-back messaging stops |
| Any new activity that drops days-since below 61 on a refresh | Premise gone (mirrors the Day 2 segment exit rule — Journey and segment agree) |
| Unsubscribe / hard bounce in SFMC | Consent/deliverability state wins immediately over any in-flight path |
| Appears in `VR_Suppression_Activated` on a later run | Unified consent changed — e.g. an opt-out recorded in another source finally reaching the unified profile |
| Plan becomes `cancelled` | Churn path, not win-back |
| Reaches the end of the second wait with no activity | Less mail is the designed ending for non-responders, not a failure state |

## What this design deliberately does not do

- **No entry from the SFMC mirror DE.** The Automation Studio mirror
  (`../sfmc-mirror/`) exists for Engagement-only audiences and parity
  QA. Feeding this Journey from both the activated DE and the mirror
  would double-enter people and mix two identity definitions in one
  Journey. One Journey, one entry source, one identity definition.
- **No branching on opens.** Email opens are not used as an engagement
  signal anywhere in this flow (see the reporting spec: opens are a
  diagnostic, not a headline, and not a branching fact).
- **No in-Journey segment logic.** The Journey consumes insight fields
  (`LifetimeOrders`, `EngagementTier`, `DaysSinceLastActivity`); it
  never recalculates them. If the branching looks wrong, the fix is
  upstream — insight or segment — where every consumer benefits.

## Sample-data expectation

Against the Day 1 sample data, this Journey enters **zero contacts**
on 2026-11-11: the one profile in the lapsing window is held out at
activation by the shared-inbox gate, so there is no activated row to
enter from. A Journey that correctly enters nobody — with the reason
traceable through segment → activation → entry gate — is the lab's
intended Day 3 result, and it is stated here in advance so the empty
entry count is read as the gates working, not as a broken Journey.
