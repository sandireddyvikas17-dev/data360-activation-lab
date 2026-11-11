-- ============================================================================
-- Automation Studio SQL — SFMC-side mirror of the Lapsing Subscriber segment
-- Lab:          Data 360 Unified Profile & Activation Lab (Day 2)
-- Brand:        VitalRoute Wellness (fictional — portfolio lab, not employer work)
--
-- WHY THIS FILE EXISTS
--   Not every audience comes from Data Cloud. Some sends still run on
--   Engagement-only data — subscribers, orders, and email engagement that
--   already live in (or are synced into) SFMC. This query rebuilds the SAME
--   lapsing logic (segments/segment-definitions.md, Segment 1) with
--   Automation Studio SQL so an Engagement-only audience lands in the same
--   place: a win-back-ready Data Extension with the same fields.
--
-- Automation:   Daily SQL Query Activity in Automation Studio, run AFTER the
--               source DEs refresh, writing with Overwrite into the target DE.
-- Target DE:    VR_Lapsing_Subscriber_Mirror
--               (SubscriberKey, EmailAddress, LifetimeOrders,
--                LastActivityDate, DaysSinceLastActivity, EngagementTier)
--
-- Source DEs (Engagement-side shapes — fictional lab schemas):
--   VR_Master_Subscribers   SubscriberKey, EmailAddress, EmailConsentStatus,
--                           IsHardBounce, PlanStatus, IsSharedInboxFlag
--   VR_Web_Orders           SubscriberKey, OrderId, OrderDate, OrderStatus
--   VR_Email_Engagement     SubscriberKey, LastEngagementDate
--                           (one row per subscriber, rolled up from
--                            send/open/click tracking extracts)
--
-- DIALECT NOTE: Automation Studio SQL is T-SQL. DATEDIFF / GETDATE() here
--   do the job CURRENT_DATE arithmetic does in the Data Cloud insights, and
--   there are no GREATEST() multi-column tricks — cross-source "latest
--   activity" is built with a UNION ALL roll-up in a subquery instead.
--
-- KNOWN LIMITS OF THE MIRROR (stated, not hidden):
--   1. Identity here is SubscriberKey, not the Unified Individual. The same
--      person under two SubscriberKeys is counted twice — the mirror cannot
--      do Day 1 identity resolution. Data Cloud membership wins on conflict.
--   2. Consent here is SFMC-side consent only. It cannot see an opt-out
--      recorded only in another source system — which is why the Day 1 model
--      puts consent on the unified profile, and why activated Data Cloud
--      audiences remain the preferred path.
--   3. App activity only appears here if it has been synced into an SFMC DE.
--      If it has not, "last activity" silently means "last SFMC-visible
--      activity" — a narrower fact wearing the same field name. Check the
--      sync before trusting the segment.
-- ============================================================================

SELECT
    s.SubscriberKey,
    s.EmailAddress,
    ISNULL(o.LifetimeOrders, 0)        AS LifetimeOrders,
    a.LastActivityDate,
    DATEDIFF(DAY, a.LastActivityDate, GETDATE()) AS DaysSinceLastActivity,
    CASE
        WHEN a.LastActivityDate IS NULL THEN 'No recorded activity'
        WHEN DATEDIFF(DAY, a.LastActivityDate, GETDATE()) <= 30 THEN 'Active'
        WHEN DATEDIFF(DAY, a.LastActivityDate, GETDATE()) <= 60 THEN 'Cooling'
        WHEN DATEDIFF(DAY, a.LastActivityDate, GETDATE()) <= 90 THEN 'Lapsing'
        ELSE 'Lapsed'
    END AS EngagementTier
FROM VR_Master_Subscribers s

-- Lifetime COMPLETED orders per subscriber (mirrors Insight 01)
LEFT JOIN (
    SELECT
        SubscriberKey,
        COUNT(OrderId) AS LifetimeOrders
    FROM VR_Web_Orders
    WHERE OrderStatus = 'completed'
    GROUP BY SubscriberKey
) o
    ON o.SubscriberKey = s.SubscriberKey

-- Latest activity across every SFMC-visible source (mirrors Insight 02):
-- completed order dates UNION email engagement, max per subscriber.
LEFT JOIN (
    SELECT
        SubscriberKey,
        MAX(ActivityDate) AS LastActivityDate
    FROM (
        SELECT SubscriberKey, OrderDate AS ActivityDate
        FROM VR_Web_Orders
        WHERE OrderStatus = 'completed'

        UNION ALL

        SELECT SubscriberKey, LastEngagementDate AS ActivityDate
        FROM VR_Email_Engagement
        WHERE LastEngagementDate IS NOT NULL
    ) activity
    GROUP BY SubscriberKey
) a
    ON a.SubscriberKey = s.SubscriberKey

WHERE
    -- Lapsing window — the same 61–90 days as the Data Cloud segment
    DATEDIFF(DAY, a.LastActivityDate, GETDATE()) BETWEEN 61 AND 90
    -- They have bought before
    AND ISNULL(o.LifetimeOrders, 0) >= 1
    -- Not churn — cancelled plans take the churn path, not win-back
    AND ISNULL(s.PlanStatus, '') <> 'cancelled'
    -- Universal gates, SFMC-side expression (consent model, Day 1)
    AND s.EmailConsentStatus = 'opted_in'
    AND ISNULL(s.IsHardBounce, 0) = 0
    AND ISNULL(s.IsSharedInboxFlag, 0) = 0

-- ============================================================================
-- QA CHECKS TO RUN ALONGSIDE (not part of the overwrite query):
--   1. Count parity: compare this DE's row count with the Data Cloud
--      Lapsing segment count for the same day. They will rarely match
--      exactly (SubscriberKey vs Unified Individual) — a LARGE gap is the
--      signal to investigate identity, not to "fix" either number.
--   2. NULL activity: subscribers with no row in the activity roll-up can
--      never enter this segment (DATEDIFF over NULL is NULL, and NULL is
--      not BETWEEN 61 AND 90). That is correct — and it is the mirror of
--      the Data Cloud rule that "no activity" stays NULL, never 0.
--   3. Gate audit: re-run the WHERE gates as standalone counts after each
--      automation run for the first week, so a consent-feed break shows up
--      as a count anomaly before it shows up as a bad send.
-- ============================================================================
