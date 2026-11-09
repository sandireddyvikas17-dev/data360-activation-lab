# DLO / DMO Mapping — VitalRoute Wellness (Day 1)

Personal portfolio lab — fictional brand, fictional data only.

## How to read this sheet

- **Source** = the system the data came from (web store, mobile app, email list)
- **DLO** = Data Lake Object: the ingested landing object in Data Cloud (source-shaped)
- **DMO** = Data Model Object: the harmonised Data Cloud model field it maps to
- Data Streams ingest the source file/API into the DLO on a schedule; mapping is then applied DLO → DMO.

## Source inventory

| # | Source | Format in lab | Refresh pattern (design) | Primary key in source | Contains |
|---|---|---|---|---|---|
| 1 | Web store | CSV (`samples/web-store-customers.csv`, `samples/web-store-orders.csv`) | Daily batch | `web_customer_id` / `order_id` | Checkout profile, orders |
| 2 | Mobile app | JSON (`samples/mobile-app-users.json`) | Daily batch (streaming would be the production option) | `app_user_id` | App login profile, plan, last active |
| 3 | Email list | CSV (`samples/email-list-subscribers.csv`) | Daily batch | `subscriber_id` | Subscription status, email preferences |

---

## 1. Web store → DLO: `WebStore_Customer_DLO`, `WebStore_Order_DLO`

### Customer profile

| Source field | DLO field | DMO | DMO field | Notes |
|---|---|---|---|---|
| `web_customer_id` | `Web_Customer_Id__c` | Individual | `Source_Id__c` (with source system = Web Store) | Source key, never the unified key on its own |
| `first_name` | `First_Name__c` | Individual | `First_Name__c` | Survivorship: see identity rules |
| `last_name` | `Last_Name__c` | Individual | `Last_Name__c` | |
| `email` | `Email__c` | Contact Point Email | `Email_Address__c` | Normalise: trim + lower-case before matching |
| `phone` | `Phone__c` | Contact Point Phone | `Telephone_Number__c` | Normalise to digits / E.164-style for matching |
| `created_at` | `Created_At__c` | Individual | `Source_Created_At__c` | Used in survivorship tie-breaks |
| `last_order_date` | `Last_Order_Date__c` | Individual (via Sales Order roll-up, Day 2) | — | Derived, not a direct profile field |

### Orders

| Source field | DLO field | DMO | DMO field | Notes |
|---|---|---|---|---|
| `order_id` | `Order_Id__c` | Sales Order | `Order_Id__c` | Primary key |
| `web_customer_id` | `Web_Customer_Id__c` | Sales Order | `Customer_Id__c` | FK to source profile, resolved to Unified Individual via identity resolution |
| `order_date` | `Order_Date__c` | Sales Order | `Order_Date__c` | |
| `plan_sku` | `Plan_Sku__c` | Sales Order Product | `Product_Sku__c` | e.g. `VR-MONTHLY`, `VR-ANNUAL` (fictional SKUs) |
| `amount` | `Amount__c` | Sales Order | `Total_Amount__c` | Sample values are invented |
| `order_status` | `Order_Status__c` | Sales Order | `Order_Status__c` | `completed` / `refunded` / `cancelled` |

## 2. Mobile app → DLO: `MobileApp_User_DLO`

| Source field | DLO field | DMO | DMO field | Notes |
|---|---|---|---|---|
| `app_user_id` | `App_User_Id__c` | Individual | `Source_Id__c` (source system = Mobile App) | Source key |
| `display_name` | `Display_Name__c` | Individual | — (split helper) | Split into first/last only if a clear space split exists; otherwise keep as display name and do not overwrite a fuller name from another source |
| `email` | `Email__c` | Contact Point Email | `Email_Address__c` | App-verified email — highest precedence for email survivorship (see identity rules) |
| `phone` | `Phone__c` | Contact Point Phone | `Telephone_Number__c` | |
| `plan_status` | `Plan_Status__c` | Engagement / Account snapshot | `Plan_Status__c` | `active` / `paused` / `cancelled` |
| `last_active_at` | `Last_Active_At__c` | Engagement | `Last_Engagement_At__c` | Feeds the Day 2 lapsing insight |
| `push_opt_in` | `Push_Opt_In__c` | Consent | See `consent/consent-model.md` | Channel-specific (push), never merged into email consent |

## 3. Email list → DLO: `EmailList_Subscriber_DLO`

| Source field | DLO field | DMO | DMO field | Notes |
|---|---|---|---|---|
| `subscriber_id` | `Subscriber_Id__c` | Individual | `Source_Id__c` (source system = Email List) | In a real SFMC source this aligns to SubscriberKey |
| `email` | `Email__c` | Contact Point Email | `Email_Address__c` | |
| `first_name` | `First_Name__c` | Individual | `First_Name__c` | Often first-name-only in email lists — survivorship must not let it erase a fuller name |
| `subscription_status` | `Subscription_Status__c` | Consent | See consent model | `subscribed` / `unsubscribed` / `bounced` |
| `consent_updated_at` | `Consent_Updated_At__c` | Consent | `Consent_Captured_At__c` | Newest explicit consent event wins for that channel |
| `signup_source` | `Signup_Source__c` | Engagement | `Acquisition_Source__c` | e.g. `checkout`, `popup`, `app` |

## Harmonisation notes

- **Email normalisation (all sources):** trim whitespace, lower-case. Do *not* strip `+tag` or dots for matching in this lab — that creates false merges for shared/family inboxes; it is noted as a rejected rule in the identity doc.
- **Phone normalisation:** strip spaces/punctuation, keep country code where present.
- **Dates:** ingest as UTC timestamps where a time exists; date-only fields stay date-only.
- **Null handling:** an empty source field never overwrites a populated unified field.
- **Data types:** IDs stay text (leading characters matter); amounts stay decimal; statuses stay a controlled picklist — free-text statuses are mapped at ingest, not in segments.
