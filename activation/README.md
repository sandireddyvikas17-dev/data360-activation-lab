# Activation — VitalRoute Wellness (Day 3)

Personal portfolio lab — fictional brand, fictional data only. Not employer work.

> **Activation is where Data Cloud projects quietly fail** — not in the
> segment logic, but at the handoff: consent not re-checked, suppression
> applied late or not at all, and insight fields re-derived in SFMC
> until "lapsing" means two different things in two systems.

This folder is the handoff, specified so it cannot fail silently:

| File | What it decides |
|---|---|
| `activation-target-spec.md` | Which segment activates to which SFMC Data Extension, in what run order, and what happens when a step fails (a failed suppression check means no activation that day) |
| `activated-data-extension-schema.md` | The exact activated DE fields — including the insight fields and consent evidence carried across — plus the non-sendable suppression DE schema |
| `suppression-consent-check.sql` | The activation-time gate: the Day 2 universal gates run again against current unified consent, producing the suppression audience **with reasons**, plus the members / held-out / sendable QA counts for the run |
| `journey-builder-entry-design.md` | The win-back Journey that consumes `VR_Lapsing_Activated`: entry gate (five checks, including the SFMC-side unsubscribe that must still win at entry), flow, goal, and exit rules |

**Day 3 sample result, stated plainly:** the Lapsing activation produces
**0 sendable rows** from the fictional sample data — the one profile in
the window is held out by the shared-inbox gate, with the reason
recorded. That is the design working, and it is the result the
reporting spec (`../reporting/dashboard-spec.md`) is built to show
honestly rather than average away.
