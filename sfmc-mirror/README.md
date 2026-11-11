# SFMC-Side Mirror — Why This Folder Exists

Personal portfolio lab — fictional brand, fictional data only.

Data Cloud is the right home for the lapsing segment: it sees all three
source systems, resolves identity first, and holds consent on the unified
profile. But real SFMC estates also run audiences that never pass through
Data Cloud — legacy automations, Engagement-only sends, and teams mid-way
through a Data Cloud rollout.

`automation-studio-lapsing-mirror.sql` rebuilds the **same** segment —
same 61–90 day window, same lifetime-orders rule, same gates — as an
Automation Studio SQL Query Activity over SFMC Data Extensions, so both
sides of the activation can be compared honestly.

The comparison is the lesson:

| | Data Cloud segment (Day 2) | SFMC mirror (this folder) |
|---|---|---|
| Identity | Unified Individual (Day 1 rules) | SubscriberKey — duplicates possible |
| Activity seen | Orders + app + email | Only what lives / is synced in SFMC |
| Consent | Unified, cross-source | SFMC-side only |
| SQL dialect | Data Cloud SQL (Calculated Insights) | T-SQL (Automation Studio) |
| Best for | Activated, cross-system audiences | Engagement-only audiences, parity QA |

Neither side is a straw man: the mirror is production-shaped SQL with QA
checks, and its limits (documented in the file header) are exactly the
reasons the Data Cloud path exists.
