-- ============================================================================
-- Calculated Insight: Engagement Tier
-- Lab:          Data 360 Unified Profile & Activation Lab (Day 2)
-- Brand:        VitalRoute Wellness (fictional — portfolio lab, not employer work)
--
-- Business question:
--   "Is this person active, cooling off, lapsing, or gone?"
--
-- The tier is a LABEL over the two insights before it — it contains no new
-- measurement. That layering is deliberate:
--   * The thresholds live in exactly one place (here), so every segment,
--     report, and journey that says "lapsing" means the same 61–90 days.
--   * If the business moves a threshold, it moves here once, and the
--     segment definitions in segments/segment-definitions.md — which filter
--     on the tier label and the raw day count — stay honest about which
--     grain they use.
--
-- Grain:        One row per Unified Individual
-- Inputs:       The outputs of 01-lifetime-orders.sql and
--               02-days-since-last-activity.sql (Calculated Insights can be
--               layered: an insight over insight outputs + the profile)
--               plus the app plan status from Engagement.
-- Output field: Engagement_Tier__c
--
-- Tier definitions:
--   No recorded activity  NULL days-since  (never ordered, never engaged)
--   Active                0–30 days since last activity
--   Cooling               31–60 days
--   Lapsing               61–90 days
--   Lapsed                91+ days
--
-- A note on plan status: tier describes ACTIVITY, not subscription state.
-- A paused plan with recent app activity is "Active" here and "paused" in
-- its plan field — segments combine the two fields rather than the tier
-- trying to encode both. One field, one meaning.
-- ============================================================================

SELECT
    ind.Unified_Individual_Id__c AS Unified_Individual_Id,
    ci_lifetime.Lifetime_Orders,
    ci_recency.Days_Since_Last_Activity,

    CASE
        WHEN ci_recency.Days_Since_Last_Activity IS NULL
            THEN 'No recorded activity'
        WHEN ci_recency.Days_Since_Last_Activity <= 30
            THEN 'Active'
        WHEN ci_recency.Days_Since_Last_Activity <= 60
            THEN 'Cooling'
        WHEN ci_recency.Days_Since_Last_Activity <= 90
            THEN 'Lapsing'
        ELSE 'Lapsed'
    END AS Engagement_Tier

FROM Individual ind
LEFT JOIN Lifetime_Orders_Insight ci_lifetime
    ON ci_lifetime.Unified_Individual_Id = ind.Unified_Individual_Id__c
LEFT JOIN Days_Since_Last_Activity_Insight ci_recency
    ON ci_recency.Unified_Individual_Id = ind.Unified_Individual_Id__c

-- ============================================================================
-- Worked check against the fictional sample data, evaluated 2026-11-10
-- (day counts from 02-days-since-last-activity.sql):
--
--   Ana Sharma        5 days, 2 orders  -> Active
--   Marcus Lee       13 days, 1 order   -> Active
--   Sofia Reyes      39 days, 1 order   -> Cooling   (plan: paused — separate
--                                                    field, see note above)
--   Jordan Ellis     87 days, 1 order   -> Lapsing
--   Priya Nair      303 days, 1 order   -> Lapsed
--   Tara Kim         NULL,    0 orders  -> No recorded activity
--
-- Six fictional profiles, five different tiers — the sample data was
-- designed on Day 1 so this table can be checked by hand.
-- ============================================================================
