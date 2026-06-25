# Extensibility tiers — what to build where (SAP clean-core guidance)

SAP recommends using the **lowest extensibility tier that does the job**:

1. **Tier 1 – Key-user / in-app extensibility** (no code): *Custom Fields & Logic*,
   *Adapt UI* (RTA), table/column personalization, custom CDS, Custom Business
   Objects. **First choice** — a key user/admin does it in the running system.
2. **Tier 2 – Developer extensibility** (ABAP Cloud, released APIs/BAdI/RAP, and
   **adaptation projects** for UI): when tier 1 cannot express it.
3. **Tier 3 – Side-by-side on SAP BTP**: when it should not live in the core.

The adaptation projects in this repo are **tier 2**. The rule we follow:

> **Create the custom *fields* with tier-1 Custom Fields & Logic where the entity
> supports it. Reserve the adaptation project (tier 2) for the grouped section,
> value helps, controller logic, custom actions, and anything tier-1 can't do.
> Authoritative business logic goes to a released BAdI / RAP on the backend.**

This means a field can appear twice in the tables below: created in tier 1, then
*arranged/validated* in tier 2. That is intentional and SAP-aligned.

---

## F1873 – Manage Sales Orders

| Custom element | Recommended tier | Notes |
|---|---|---|
| Fields: denier, shade, lustre, contract link | **Tier 1** Custom Fields & Logic | Add on the Sales Order; publish to the OData service/UI |
| Place fields on the Object Page (simple) | **Tier 1** Adapt UI | If a flat placement is enough, no project needed |
| Grouped "Textile Attributes" section + shade value help | **Tier 2** adaptation project | Custom fragment + `valueHelpRequest` — beyond tier 1 |
| `onBeforeSave` guard | **Tier 2** adaptation project | Client-side only |
| Custom list column (shade) | **Tier 1** Adapt UI / personalization | Key user can add the column |
| Pricing / availability / validation (old SAPMZ_SO_CREATE) | **Backend** released BAdI / RAP | Not UI; authoritative logic |

## F3069 – Confirm Production Operation

| Custom element | Recommended tier | Notes |
|---|---|---|
| Fields: shade, dye-lot, recipe, temperature, WIP batch | **Tier 1** Custom Fields *(verify support)* | Production confirmation may have limited key-user extensibility; fall back to **Tier 2 CDS extend** if not exposed |
| Grouped "Dyeing Confirmation" section + value help | **Tier 2** adaptation project | Custom fragment / panel |
| Dye-lot & temperature guards | **Tier 2** adaptation project | Client-side only |
| Dyeing confirmation logic + WIP batch update | **Backend** released BAdI / RAP | Authoritative posting & batch update |

## F0867A – Manage Outbound Deliveries

| Custom element | Recommended tier | Notes |
|---|---|---|
| Fields: challan no/date, vehicle, transporter, e-way bill | **Tier 1** Custom Fields & Logic | Add on the outbound delivery |
| Grouped "Delivery Challan" section + "Print Challan" button | **Tier 2** adaptation project | Custom fragment + action handler |
| `onBeforeSave` guard | **Tier 2** adaptation project | Client-side only |
| Custom list column (challan no) | **Tier 1** Adapt UI / personalization | Key user can add the column |
| Challan **print** (old ZRPT_DELIVERY_CHALLAN) | **Config** Output Management + Adobe form | Not code |

---

⚠️ Whether a given standard entity supports tier-1 Custom Fields & Logic depends
on your release/FPS. Confirm per app in **Custom Fields & Logic** (and the SAP
Help Portal) before deciding tier 1 vs tier 2 for each field. When in doubt, the
adaptation project already covers it as a working fallback.
