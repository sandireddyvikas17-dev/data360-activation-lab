# Identity Resolution Rules — VitalRoute Wellness

Personal portfolio lab — fictional brand, fictional data only.
Day 1 artefact. This is the document the Day 1 LinkedIn post is about.

> **Core claim of this lab:** identity resolution rules matter more than match keys.
> A match key tells you two records *could* be the same person. The rules around it decide whether you *should* merge them, what happens when the sources disagree, and how you explain the merge later. Getting the key right and the rules wrong still creates a bad unified profile.

## 1. What we are resolving

Three source profiles per person, at most:

| Source | Source key | What it is best at |
|---|---|---|
| Web store | `web_customer_id` | Orders, checkout identity |
| Mobile app | `app_user_id` | Verified login email, current plan, last activity |
| Email list | `subscriber_id` | Email consent status, subscription history |

The output is one **Unified Individual** per real person, with every source record linked to it and traceable.

## 2. Match keys (in priority order)

All comparisons use normalised values (see `data-model/dlo-dmo-mapping.md`).

| Priority | Match rule | Type | Action on match |
|---|---|---|---|
| 1 | Exact normalised **email** match | Deterministic | Link records to the same Unified Individual |
| 2 | Exact normalised **phone** match **AND** last-name match | Deterministic, composite | Link — phone alone is never enough (shared/family phones, recycled numbers) |
| 3 | Source cross-reference: web-store checkout email that also appears as the app account email (covered by Rule 1 in this lab's data, kept explicit for the production API case) | Deterministic | Link |
| — | Fuzzy name + address / name similarity alone | **Not used** | No auto-merge. Flag for manual review only. |

### Rules deliberately NOT used — and why

- **Email alone with `+tag` / dot stripping:** rejected. It over-merges shared inboxes and creates one profile for a household that buys separately.
- **Phone alone:** rejected. Phones are shared and recycled; phone is a supporting key, never a sole key.
- **Name alone / fuzzy name:** rejected for auto-merge. Common names collide constantly, and a wrong merge is much harder to undo than a missed merge is to fix later.
- **Device ID alone:** rejected. One person has several devices; one device can be shared.

**Bias of this ruleset: prefer a missed merge over a wrong merge.** A missed merge costs a duplicate count. A wrong merge costs wrong personalisation, wrong consent handling, and a person's data shown in another person's journey. Those are not equivalent errors.

## 3. Precedence (which source is trusted first, overall)

1. **Mobile app** — verified login identity, most recently maintained by the person themselves
2. **Web store** — transactional identity, verified at payment
3. **Email list** — oldest, least maintained, most likely to contain typos and stale names

Precedence is the *default*. Survivorship below overrides it per field — precedence alone is too blunt to run a profile on.

## 4. Survivorship — which value wins, per field

| Unified field | Winning source / rule | Why |
|---|---|---|
| Email (primary contact point) | App-verified email if present; else web-store email; else email-list email | The email the person actually logs in with is the one most likely to be current and theirs |
| First / last name | Most complete value wins: a full first+last from app or web store beats a first-name-only value from the email list. An empty value never overwrites a populated one. | Email lists routinely hold first name only; letting them win erases good data |
| Phone | Most recently updated non-empty phone, provided it passed normalisation | Phones change; recency is the best available signal here |
| Plan status | Mobile app (current plan state) | The app is the system of record for an active/paused/cancelled plan |
| Last activity date | **Latest** timestamp across *all* sources (orders, app activity, email engagement) | Lapsing logic (Day 2) must see activity wherever it happened, not just in one system |
| Consent (per channel) | **Newest explicit consent event for that channel wins** — except that an unsubscribe is never overwritten by an older or implicit opt-in. See `consent/consent-model.md`. | Consent is a legal state, not a profile preference; it gets its own rule, not generic last-write-wins |
| Created / first-seen date | **Earliest** date across sources | Tenure should reflect when the relationship actually started |

## 5. Conflict & review handling

- **Two different verified emails, same phone + last name:** link by Rule 2, keep *both* emails as Contact Points, set the app email as primary. Do not delete the second email — it may be the checkout email orders reference.
- **One email, two clearly different people** (different last names, different phones, disjoint order history): do **not** auto-merge on email alone in a manual-review pass; flag as `possible_shared_inbox`. Shared/family inboxes are real, and forcing them into one profile is a wrong merge.
- **No match:** create a new Unified Individual. That is the safe default.
- **Every link keeps provenance:** source system + source ID + rule that linked it + date linked. If a merge is ever questioned, the answer must be readable from the profile, not reconstructed from logs.

## 6. Worked examples (from the fictional sample data)

Sample files are in `samples/`. These examples are designed into that data on purpose:

1. **Same person, three emails-adjacent records:** a web-store customer and an app user sharing one normalised email merge by Rule 1; their email-list record with the same email joins them. Survivorship keeps the app email as primary and the fullest name.
2. **Same person, different emails:** a web-store record and an app record with different emails but the same normalised phone *and* last name merge by Rule 2, with both emails retained.
3. **Shared inbox, different people:** the web-store record for Jordan Ellis (W1004) and the email-list record under the name Riley (S3005) share `household.shared@example.com` but have different last names and phones — flagged `possible_shared_inbox` for review, not treated as one person without a second signal.
4. **No match:** Tara Kim (S3006) never bought or used the app in the sample data, so she stays as a single-source Unified Individual, with email consent intact. Single-source is a valid unified profile, not an error.

## 7. What Day 2 builds on this

Calculated Insights and segments read the **Unified Individual**, never a single source. If this ruleset is wrong, every insight and segment built on it is wrong in the same direction — which is why this document comes before any SQL.
