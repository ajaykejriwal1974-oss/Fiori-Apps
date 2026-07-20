# Clean KGPL role — curate to exactly the 62 standard apps (+ 38 custom)

**Goal:** replace the six bloated `ZKEJ_SAP_BR_*` derived roles (full copies of
`SAP_BR_*`, ~800 mostly-irrelevant apps each — Brazil Nota Fiscal, external-agent
commissions, condition contracts, rebates, dozens of `Schedule…` batch apps) with
**one clean role** that exposes only what KGPL uses:

```
ZKGPL_ALL  (business role / PFCG)
├── ZKGPL_BC_CUSTOM     → 38 custom + Fiori-Elements + analytics apps   (already built)
└── ZKGPL_BC_STANDARD   → the 62 standard SAP Fiori apps below          (build now)
```

Authoritative scope = the published plan
<https://ajaykejriwal1974-oss.github.io/Fiori-Apps/> — **62 standard apps**
(FI 15 · MM 12 · PM 12 · QM 10 · SD 9 · PP 5 · WF 1). Backend already activated
(345 services, run 19.07) so every reference resolves.

---

## Build steps

### 1 · Create catalog `ZKGPL_BC_STANDARD`
Launchpad Designer (CONF) — same place as `ZKGPL_BC_CUSTOM`:
`https://122.179.133.205:5200/sap/bc/ui5_ui5/sap/arsrvc_upb_admn/main.html?sap-client=500&scope=CONF&sap-language=EN`
- **+ New Catalog** → Title `KGPL Standard Apps` · ID `ZKGPL_BC_STANDARD`.

### 2 · Add the 62 apps as references (by name)
For each app in the table below: in the catalog, **Add Tile → reference an
existing tile** (or open the SAP source catalog and *Add Reference*), search by
the **app name**, add it. The standard target mapping ships with the app, so a
reference is enough — no new target mapping to author. Tick as you go.

### 3 · Create role `ZKGPL_ALL` (PFCG)
- `PFCG` → create role `ZKGPL_ALL` → **Menu** tab → *Insert → SAP Fiori Tile
  Catalog* → add **`ZKGPL_BC_CUSTOM`** and **`ZKGPL_BC_STANDARD`**.
- **Authorizations** tab → generate profile (pull SU24 defaults for the apps).
- **User** tab → assign the KGPL users. Save + generate.

### 4 · Drop the bloated roles
Remove `ZKEJ_SAP_BR_AP_ACCOUNTANT`, `…_BILLING_CLERK`, `…_EMPLOYEE`,
`…_INTERNAL_SALES_REP`, `…_PURCHASING_MANAGER`, `…_WAREHOUSE_CLERK` from the
users (keep the role objects until parallel-run confirms nothing is missing).

### 5 · Verify
`/UI2/INVALIDATE_GLOBAL_CACHE` → re-login → FLP shows ~100 tiles, no 800-app
noise, no dead tiles. `/IWFND/ERROR_LOG` clean.

---

## The 62 standard apps (checklist)

### FI — 15
- [ ] Manage Journal Entries — F0717A — SAP_BR_GL_ACCOUNTANT
- [ ] Post General Journal Entries — F0718 — SAP_BR_GL_ACCOUNTANT
- [ ] Display Line Items in G/L — F0706 — SAP_BR_GL_ACCOUNTANT
- [ ] Trial Balance — F0996A — SAP_BR_GL_ACCOUNTANT
- [ ] Manage Customer Line Items — F0711 — SAP_BR_AR_ACCOUNTANT
- [ ] Post Incoming Payments — F1345 — SAP_BR_AR_ACCOUNTANT
- [ ] Manage Supplier Line Items — F0712 — SAP_BR_AP_ACCOUNTANT
- [ ] Post Outgoing Payments — F1612 — SAP_BR_AP_ACCOUNTANT
- [ ] Schedule Automatic Payments — F110 — SAP_BR_AP_ACCOUNTANT
- [ ] Manage Credit Memo Requests — F0696 — SAP_BR_BILLING_CLERK
- [ ] Post Asset Acquisition — ABZON — SAP_BR_AA_ACCOUNTANT
- [ ] Asset Values / Explorer — AW01N — SAP_BR_AA_ACCOUNTANT
- [ ] Reprocess Bank Statement Items — F1681 — SAP_BR_CASH_SPECIALIST
- [ ] Manage Documented Credit Decisions — F5587A — SAP_BR_CREDIT_CONTROLLER
- [ ] Maintenance Order Budget — KO22 — SAP_BR_OVERHEAD_ACCOUNTANT

### MM — 12
- [ ] Manage Purchase Orders — F0842A — SAP_BR_PURCHASER
- [ ] Manage Purchase Requisitions — F2229 — SAP_BR_PURCHASER
- [ ] Manage Purchasing Info Records — ME11 — SAP_BR_PURCHASER
- [ ] Compare Supplier Quotations — F2324 — SAP_BR_PURCHASER
- [ ] Release Purchase Orders — F2872 — SAP_BR_PURCHASING_MANAGER
- [ ] Post Goods Receipt for Purchasing Doc — F0843 — SAP_BR_WAREHOUSE_CLERK
- [ ] Manage Physical Inventory — MI01 — SAP_BR_WAREHOUSE_CLERK
- [ ] Stock — Multiple Materials — MMBE — SAP_BR_WAREHOUSE_CLERK
- [ ] Manage Material Master — F1602 — SAP_BR_BUYER
- [ ] Maintain Bill of Material — CS01/02/03 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Monitor Material Coverage (MRP) — F0247 — SAP_BR_MRP_CONTROLLER
- [ ] Create Supplier Invoice — F0859 — SAP_BR_AP_ACCOUNTANT

### PM — 12
- [ ] Report and Repair Malfunction — F2023 — SAP_BR_MAINTENANCE_TECHNICIAN
- [ ] Perform Maintenance Jobs — F5104A — SAP_BR_MAINTENANCE_TECHNICIAN
- [ ] Request Maintenance — F1511A — SAP_BR_EMPLOYEE_MAINTENANCE
- [ ] Manage Maintenance Notifications & Orders — F4604 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Manage Maintenance Plans — F5325 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Mass Schedule Maintenance Plans — F2774 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Advanced Scheduling Board — F5460 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Breakdown Analysis (EAM KPI) — F2812 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Process Task List (Planner) — W0021 — SAP_BR_MAINTENANCE_PLANNER
- [ ] Process Measuring Point — W0031 — SAP_BR_MAINTENANCE_TECHNICIAN
- [ ] Process Measurement Document — W0014 — SAP_BR_MAINTENANCE_TECHNICIAN
- [ ] Process Technical Object — W0029 — SAP_BR_MD_SPECIALIST_EAM

### QM — 10
- [ ] Manage Inspection Lots — QA32/QA33 — SAP_BR_QUALITY_ENGINEER
- [ ] Record Inspection Results — F2170 — SAP_BR_QUALITY_TECHNICIAN
- [ ] Record Results for Inspection Points — F2689 — SAP_BR_QUALITY_TECHNICIAN
- [ ] Manage Usage Decisions — QA11 — SAP_BR_QUALITY_ENGINEER
- [ ] Manage Quality Notifications — QM01 — SAP_BR_QUALITY_ENGINEER
- [ ] Create Quality Certificate (Delivery) — QC22 — SAP_BR_QUALITY_ENGINEER
- [ ] Manage Quality Info Records — QI01 — SAP_BR_QUALITY_ENGINEER
- [ ] Master Inspection Characteristics — F2219 — SAP_BR_QUALITY_PLANNER
- [ ] Manage Inspection Plans — F3788 — SAP_BR_QUALITY_PLANNER
- [ ] Manage Catalogs / Code Groups — QS41 — SAP_BR_QUALITY_PLANNER

### SD — 9
- [ ] Manage Sales Orders — F1873 — SAP_BR_INTERNAL_SALES_REP  *(+ your ext adaptation)*
- [ ] Manage Sales Contracts — VA42 — SAP_BR_INTERNAL_SALES_REP  *(+ your ext adaptation)*
- [ ] Manage Outbound Deliveries — F0867A — SAP_BR_SHIPPING_SPECIALIST  *(+ your ext adaptation)*
- [ ] Sales Order Fulfillment — Issues — F0251 — SAP_BR_INTERNAL_SALES_REP
- [ ] Manage Prices — Sales — VK11 — SAP_BR_INTERNAL_SALES_REP
- [ ] Create Billing Documents — F0798 — SAP_BR_BILLING_CLERK
- [ ] Manage Billing Documents — F0797 — SAP_BR_BILLING_CLERK
- [ ] Manage Business Partner (Customer) — BP/XD03 — SAP_BR_BUPA_MASTER_SPECIALIST
- [ ] Release Sales Contracts — VA42 — SAP_BR_INTERNAL_SALES_REP

### PP — 5
- [ ] Confirm Production Operation — F3069 — SAP_BR_PRODN_OPERATOR  *(+ your ext adaptation)*
- [ ] Manage Batches — F2462 — SAP_BR_WAREHOUSE_CLERK
- [ ] Manage Work Centers — F6175 — SAP_BR_PRODN_PLANNER
- [ ] Manage Work Center Capacity — F3289 — SAP_BR_PRODN_PLANNER
- [ ] Manage Bill of Operations — CA01/02/03 — SAP_BR_MANUF_ENGINEER

### Workflow — 1
- [ ] My Inbox (All Items) — F0862 — SAP_BR_EMPLOYEE

---

> **Note on the 3 SD + 1 PP apps marked *ext adaptation*** — F1873, VA42
> contracts, F0867A, F3069 are also the base apps your four adaptation projects
> extend. Reference the **standard** app here; the adaptation adds the KGPL
> fields/actions on top (same tile intent). Don't double-list.
