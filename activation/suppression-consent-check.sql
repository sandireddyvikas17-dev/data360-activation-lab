-- ============================================================================
-- Suppression / Consent Check — run at activation time (Day 3)
-- Lab:          Data 360 Unified Profile & Activation Lab (Day 3)
-- Brand:        VitalRoute Wellness (fictional — portfolio lab, not employer work)
--
-- WHY THIS FILE EXISTS
--   "Activation is where Data Cloud projects quietly fail."
--
--   The segment (Day 2) already applied the universal consent gates at
--   segment build. This query runs the SAME gates again, at activation,
--   for three reasons segment build cannot cover:
--
--     1. TIME — consent captured between segment build and activation
--        must win. A person who unsubscribed yesterday is not sendable
--        today because a segment built the day before said they were.
--     2. PLACE — this check reads the CURRENT unified consent state,
--        not the state the segment happened to be built from.
--     3. PROOF — its output is not just a filtered audience. It produces
--        the suppression audience WITH REASONS, so every held-out profile
--        is lookup-able to the rule that held it out.
--
-- WHERE IT RUNS
--   Step 5 of the daily run order in activation-target-spec.md:
--   after segment refresh, before ANY activation. If this check fails
--   or cannot run, no audience activates that day.
--
-- DIALECT NOTE
--   Written in the same Data Cloud SQL style as insights/ (the check is
--   evaluated against the unified profile before activation). The
--   activated suppression DE it feeds is VR_Suppression_Activated
--   (schema: activated-data-extension-schema.md).
--
-- INPUTS (logical DMO names, as in insights/README.md):
--   Individual            — Unified Individual + primary contact point
--   Unified Consent       — per-channel consent on the unified profile
--                           (consent/consent-model.md)
--   Segment Membership    — the refreshed Day 2 segment members for the
--                           segment being activated
--
-- OUTPUTS:
--   Query 1 — the SUPPRESSION set for this run (feeds
--             VR_Suppression_Activated): segment members who must NOT
--             activate, each with exactly one SuppressionReason.
--   Query 2 — the QA COUNTS for this run: members, held out by reason,
--             and the sendable remainder. These three numbers are
--             reported for every run (see reporting/dashboard-spec.md);
--             a run is not "done" until they are read.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- QUERY 1 — Suppression set for this activation run
--
-- One row per held-out segment member. Reason precedence is deliberate:
-- the FIRST matching reason in the CASE is the recorded one, ordered so
-- the strongest state wins the record:
--   unified_opt_out     — the person said no; nothing outranks this
--   hard_bounce         — the contact point is undeliverable
--   possible_shared_inbox — identity review flag (Day 1): held out until
--                         the merge question is resolved
--   consent_unknown     — no explicit opt-in on the unified profile;
--                         absence of an opt-out is NOT an opt-in
--                         (consent model, Rule 4)
-- ----------------------------------------------------------------------------

SELECT
    m.Unified_Individual_Id__c        AS Unified_Individual_Id,
    ind.Primary_Email__c              AS Email_Address,
    CASE
        WHEN c.Email_Consent_Status__c = 'opted_out'
            THEN 'unified_opt_out'
        WHEN ind.Primary_Contact_Point_Status__c = 'bounced_hard'
            THEN 'hard_bounce'
        WHEN ind.Possible_Shared_Inbox__c = TRUE
            THEN 'possible_shared_inbox'
        WHEN c.Email_Consent_Status__c IS NULL
          OR c.Email_Consent_Status__c <> 'opted_in'
            THEN 'consent_unknown'
    END                               AS Suppression_Reason,
    CURRENT_TIMESTAMP                 AS Suppressed_At

FROM Segment_Membership m
JOIN Individual ind
    ON  ind.Unified_Individual_Id__c = m.Unified_Individual_Id__c
LEFT JOIN Unified_Consent c
    ON  c.Unified_Individual_Id__c = m.Unified_Individual_Id__c
    AND c.Channel__c = 'email'

WHERE
    -- A member is held out if ANY gate fails. The sendable condition is
    -- the strict conjunction in Query 2 — never "not obviously bad."
       c.Email_Consent_Status__c IS NULL
    OR c.Email_Consent_Status__c <> 'opted_in'
    OR ind.Primary_Contact_Point_Status__c = 'bounced_hard'
    OR ind.Possible_Shared_Inbox__c = TRUE

-- Worked check against the fictional sample data (Lapsing segment,
-- evaluated 2026-11-11):
--   Jordan Ellis — meets the activity rules, flagged
--                  possible_shared_inbox (Day 1, worked example 3)
--                  -> 1 suppression row, reason possible_shared_inbox.
--   Sofia Reyes  — not a lapsing member at all (39 days, Cooling), so
--                  she never reaches this check for THIS segment; her
--                  unified_opt_out suppression is produced when any
--                  segment she would otherwise enter is activated, and
--                  she stands in the suppression audience with reason
--                  unified_opt_out. The check is per-activation; her
--                  opt-out is universal in effect because every email
--                  segment runs it.


-- ----------------------------------------------------------------------------
-- QUERY 2 — QA counts for this activation run
--
-- Sendable = member AND email consent opted_in AND not hard-bounced
-- AND not shared-inbox-flagged. This is the Day 2 universal gate,
-- restated at activation — intentionally the same words, so the two
-- gates can be compared and can never quietly drift apart.
-- ----------------------------------------------------------------------------

SELECT
    COUNT(*)                                                   AS Segment_Members,
    SUM(CASE WHEN NOT (
            c.Email_Consent_Status__c = 'opted_in'
        AND COALESCE(ind.Primary_Contact_Point_Status__c, '') <> 'bounced_hard'
        AND COALESCE(ind.Possible_Shared_Inbox__c, FALSE) = FALSE
    ) THEN 1 ELSE 0 END)                                       AS Held_Out,
    SUM(CASE WHEN
            c.Email_Consent_Status__c = 'opted_in'
        AND COALESCE(ind.Primary_Contact_Point_Status__c, '') <> 'bounced_hard'
        AND COALESCE(ind.Possible_Shared_Inbox__c, FALSE) = FALSE
    THEN 1 ELSE 0 END)                                         AS Sendable

FROM Segment_Membership m
JOIN Individual ind
    ON  ind.Unified_Individual_Id__c = m.Unified_Individual_Id__c
LEFT JOIN Unified_Consent c
    ON  c.Unified_Individual_Id__c = m.Unified_Individual_Id__c
    AND c.Channel__c = 'email'

-- Worked check (Lapsing segment, sample data, 2026-11-11):
--   Segment_Members = 1 (Jordan Ellis, on activity rules before gates —
--   see segments/segment-definitions.md for how the segment states its
--   own gated result) / Held_Out = 1 / Sendable = 0.
--   Zero sendable is the CORRECT result for this run. A future run that
--   shows Sendable = 0 with Held_Out = 0 and Segment_Members = 0 is a
--   different fact (an empty segment) and must not be reported as if it
--   were the same thing — the three counts together are the result,
--   never the sendable count alone.
-- ============================================================================
