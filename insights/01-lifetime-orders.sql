-- ============================================================================
-- Calculated Insight: Lifetime Orders
-- Lab:          Data 360 Unified Profile & Activation Lab (Day 2)
-- Brand:        VitalRoute Wellness (fictional — portfolio lab, not employer work)
--
-- Business question:
--   "How much has this person actually bought from us, ever?"
--
-- Grain:        One row per Unified Individual
-- Inputs (DMOs, see data-model/dlo-dmo-mapping.md):
--                 Individual      — the unified profile (Day 1)
--                 Sales Order     — harmonised orders from the web store
-- Output fields on the Unified Individual:
--                 Lifetime_Orders__c       (count of completed orders)
--                 Lifetime_Value__c        (sum of completed order amounts)
--                 First_Order_Date__c      (earliest completed order date)
--                 Last_Order_Date__c       (most recent completed order date)
-- Refresh:      On the daily Data Stream refresh (see insights/README.md)
--
-- Rules:
--   * Completed orders only — refunded / cancelled never count.
--   * Orders join to the Unified Individual, NOT to the web-store customer
--     id, so orders placed under a second email still count once identity
--     resolution (Day 1, Rule 2) has linked the records.
--   * A person with no completed orders gets 0 / 0.00 here — that IS a fact
--     about buying. (Contrast with days-since-last-activity, where "none"
--     must stay NULL.)
-- ============================================================================

SELECT
    ind.Unified_Individual_Id__c            AS Unified_Individual_Id,
    COUNT(ord.Order_Id__c)                  AS Lifetime_Orders,
    COALESCE(SUM(ord.Total_Amount__c), 0)   AS Lifetime_Value,
    MIN(ord.Order_Date__c)                  AS First_Order_Date,
    MAX(ord.Order_Date__c)                  AS Last_Order_Date
FROM Individual ind
LEFT JOIN Sales_Order ord
    ON  ord.Customer_Id__c = ind.Unified_Individual_Id__c
    AND ord.Order_Status__c = 'completed'
GROUP BY
    ind.Unified_Individual_Id__c

-- ============================================================================
-- Worked check against the fictional sample data (samples/web-store-orders.csv),
-- evaluated 2026-11-10:
--
--   Ana Sharma     2 completed orders   Lifetime_Value 480.00
--                  (2025-03-14 annual + 2026-03-14 annual renewal)
--   Marcus Lee     1 completed order    Lifetime_Value  25.00
--   Priya Nair     1 completed order    Lifetime_Value  25.00
--   Jordan Ellis   1 completed order    Lifetime_Value  25.00
--   Sofia Reyes    1 completed order    Lifetime_Value 240.00
--   Tara Kim       0 completed orders   Lifetime_Value   0.00
--                  (email-list only — a real unified profile with no orders;
--                   the LEFT JOIN is what keeps her in the result at all)
-- ============================================================================
