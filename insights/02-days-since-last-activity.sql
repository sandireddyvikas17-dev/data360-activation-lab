-- ============================================================================
-- Calculated Insight: Days Since Last Activity
-- Lab:          Data 360 Unified Profile & Activation Lab (Day 2)
-- Brand:        VitalRoute Wellness (fictional — portfolio lab, not employer work)
--
-- Business question:
--   "How long has it been since this person did ANYTHING with us?"
--
-- This is the insight the "lapsing subscriber" segment is built on
-- (segments/segment-definitions.md). Walk-through:
--
--   1. "Anything" is deliberate. A subscriber who stopped opening email but
--      ordered last week is not lapsing — they changed channel. A subscriber
--      whose app went quiet but who clicked an email yesterday is not
--      lapsing either. Lapsing is about the RELATIONSHIP going quiet, so
--      the date we measure from is the latest activity in ANY source.
--   2. That is the Day 1 survivorship rule applied as an insight:
--      last activity = MAX(order date, app last-active, email engagement).
--   3. The segment then asks one simple question of this field:
--      is it between 61 and 90 days? (See the segment doc for why the
--      window is a window — not just "more than 60.")
--
-- Grain:        One row per Unified Individual
-- Inputs (DMOs):
--                 Individual   — unified profile
--                 Sales Order  — completed order dates
--                 Engagement   — app last-active + email engagement timestamps
-- Output fields on the Unified Individual:
--                 Last_Activity_At__c          (latest activity, any source)
--                 Days_Since_Last_Activity__c  (whole days from that date
--                                               to the insight run date)
-- Refresh:      Daily — this field is only meaningful if it advances daily.
--
-- Rules:
--   * No recorded activity anywhere => Days_Since_Last_Activity stays NULL.
--     NULL means "we have never seen this person do anything," which is a
--     different business fact from 0 ("active today") and from 200
--     ("went quiet long ago"). Segments must handle NULL explicitly.
--   * Future-dated source timestamps are a data-quality error, not
--     "negative days" — they surface as negative values here on purpose so
--     they are visible in QA rather than silently clamped.
-- ============================================================================

SELECT
    ind.Unified_Individual_Id__c AS Unified_Individual_Id,

    GREATEST(
        COALESCE(MAX(ord.Order_Date__c), DATE '1900-01-01'),
        COALESCE(MAX(eng.Last_Engagement_At__c), DATE '1900-01-01')
    ) AS Last_Activity_At,

    CASE
        WHEN MAX(ord.Order_Date__c) IS NULL
         AND MAX(eng.Last_Engagement_At__c) IS NULL
            THEN NULL  -- never active anywhere: leave it honestly empty
        ELSE
            CURRENT_DATE - GREATEST(
                COALESCE(MAX(ord.Order_Date__c), DATE '1900-01-01'),
                COALESCE(MAX(eng.Last_Engagement_At__c), DATE '1900-01-01')
            )
    END AS Days_Since_Last_Activity

FROM Individual ind
LEFT JOIN Sales_Order ord
    ON  ord.Customer_Id__c = ind.Unified_Individual_Id__c
    AND ord.Order_Status__c = 'completed'
LEFT JOIN Engagement eng
    ON  eng.Individual_Id__c = ind.Unified_Individual_Id__c
GROUP BY
    ind.Unified_Individual_Id__c

-- ============================================================================
-- Worked check against the fictional sample data, evaluated 2026-11-10:
-- (last activity = latest of last completed order / app last-active)
--
--   Ana Sharma     last activity 2026-11-05 (app)    ->   5 days
--   Marcus Lee     last activity 2026-10-28 (app)    ->  13 days
--   Sofia Reyes    last activity 2026-10-02 (order)  ->  39 days
--                  (app last-active 2026-07-19 is OLDER, so the order wins —
--                   this is the cross-source MAX doing its job)
--   Jordan Ellis   last activity 2026-08-15 (order)  ->  87 days
--   Priya Nair     last activity 2026-01-11 (order)  -> 303 days
--   Tara Kim       no orders, no app, no engagement  -> NULL
--
-- Read against the segment windows in segments/segment-definitions.md:
-- Jordan (87) is inside the 61–90 lapsing window; Priya (303) has already
-- passed through it into Lapsed; Sofia (39) is only "cooling" as a fact —
-- and is separately un-sendable on email consent (Day 1 consent model).
-- ============================================================================
