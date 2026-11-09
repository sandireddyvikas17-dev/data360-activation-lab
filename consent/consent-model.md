# Consent Model — VitalRoute Wellness

Personal portfolio lab — fictional brand, fictional data only.

## Principle

Consent lives on the **Unified Individual, per channel** — not inside one source system.
A person does not opt out "in the email list." They opt out of email. Every activation checks the unified consent state, not the source it happened to pull the address from.

## Channels in scope

| Channel | Source(s) that can change it | Values |
|---|---|---|
| Email | Email list (primary), web-store checkout opt-in, app account settings | `opted_in` / `opted_out` / `bounced_hard` / `unknown` |
| Push | Mobile app only | `opted_in` / `opted_out` / `unknown` |
| SMS | None in Day 1 sources — modelled, not populated | `opted_in` / `opted_out` / `unknown` |

Channel consent is **never merged across channels**: a push opt-in says nothing about email, and an email opt-out says nothing about push.

## What is stored (per person, per channel)

| Field | Meaning |
|---|---|
| `Consent_Status__c` | Current status for that channel (values above) |
| `Consent_Captured_At__c` | When the deciding event happened |
| `Consent_Source__c` | Which system recorded the deciding event |
| `Consent_Basis__c` | How it was captured in the source (e.g. `explicit_form`, `checkout_checkbox`, `unsubscribe_link`, `app_setting`) |

Storing source + timestamp + basis alongside the status is what makes the state auditable later.

## Merge rules (applied during identity resolution)

1. **Newest explicit event for that channel wins** — e.g. a newer in-app email opt-in supersedes an older list opt-in/opt-out state, because it is the person's most recent explicit choice.
2. **An unsubscribe is never overwritten by an implicit or older opt-in.** Only a newer, explicit opt-in (a deliberate action by the person, not a pre-ticked box or an import default) can move `opted_out` back to `opted_in`.
3. **Hard bounce is a deliverability state, not a preference.** `bounced_hard` suppresses sends for that contact point, but if the person provides a new email, the new contact point starts from its own consent state — the bounce does not follow the person to a new address, and the preference does not either.
4. **`unknown` never activates.** If no source holds an explicit email opt-in for the unified profile, the profile is not activated for email. Absence of an opt-out is not an opt-in.
5. **Source precedence does not apply to consent.** Identity survivorship prefers the app for profile fields; consent instead follows recency + explicitness (Rules 1–2), whichever source recorded it.

## Enforcement points

| Point | Check |
|---|---|
| Segment build (Day 2) | Email segments include only unified profiles with email `opted_in` |
| Activation (Day 3) | Consent re-checked at activation time, not just at segment build — consent can change between the two |
| SFMC side (Day 3) | Activated Data Extension carries the consent status + timestamp, and the Journey entry includes a suppression check so an SFMC-side unsubscribe after activation still wins at send time |
| Suppression | Unified `opted_out` / `bounced_hard` profiles are written to the suppression audience, with a reason value, mirroring the suppression-first pattern from Project #1 |

## Worked example (fictional sample data)

In the sample data, Sofia Reyes is `subscribed` earlier in her history and then `unsubscribed` on 2026-09-01 in the email list (`samples/email-list-subscribers.csv`, S3004), while her web-store and app profiles still exist and look marketable. Unified email consent = **`opted_out`** (Rule 1: newest explicit event; Rule 2: protected). Day 2/3 must not activate her for email just because other source profiles still exist — that disagreement between sources is exactly the bug this model exists to prevent.
