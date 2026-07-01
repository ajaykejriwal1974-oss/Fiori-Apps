# Kejriwal — Fiori App Portfolio: coverage & mapping

S/4HANA 2025 upgrade — every launchpad tile mapped to its SAP module, type, Fiori/app ID, business role and the Z transaction it replaces. Generated from `demo/build.py` (`python3 demo/gen_coverage.py`).

**Live launchpad:** <https://ajaykejriwal1974-oss.github.io/Fiori-Apps/>

**Totals:** 102 tiles — 60 standard, 13 master data, 13 analytics, 12 custom, 4 extended.

| Module | Tiles |
|---|--:|
| Production (PP) | 24 |
| Sales & Distribution (SD) | 18 |
| Materials & Inventory (MM) | 18 |
| Quality (QM) | 11 |
| Finance (FI) | 18 |
| Maintenance (PM) | 12 |
| Workflow & Approvals | 1 |

> **Type key** — **Custom** = freestyle app, runs live in the demo; **Extended** = adaptation of a standard app; **Standard** = delivered app adopted as-is; **Master data** = managed-RAP → Fiori Elements; **Analytics** = CDS analytical query. App IDs shown as `F####`/`W####` are library-verified; plain transaction codes (e.g. `VK11`, `MI01`) are the reliable anchor where the Fiori F-number varies by release — confirm in your FES.

## Production (PP)

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| Batch Status | Custom | freestyle (custom RAP) | — | custom business role | ZBATCHD, ZBATCH_CLS |
| Dyeing Packing | Custom | freestyle (custom RAP) | — | custom business role | ZPACK01D/02D/03D, ZREPACKD |
| Packing Details | Custom | freestyle (custom RAP) | — | custom business role | ZPACK01/01N/02/02N/03, ZREPACK |
| Post Packing & GR | Custom | freestyle (custom RAP) | — | custom business role | ZPOST01 |
| Palletization | Custom | freestyle (custom RAP) | — | custom business role | ZPALLET/1, ZPAL_BOX, ZSOL_ASRS |
| MTOS Process | Custom | freestyle (custom RAP) | — | custom business role | ZMTOS, ZHUINV |
| Confirm Production Operation | Extended | F3069 | — | (base-app role) | ZCO11N / ZCO11A |
| Manage Batches | Standard | F2462 | MSC3N | SAP_BR_WAREHOUSE_CLERK | ZBATCH01/02/03(N) |
| Manage Work Centers | Standard | F6175 | CR01/02/03 | SAP_BR_PRODN_PLANNER | one app for all work centres — PP machine (cat. 0001) & PM maintenance (cat. 0005) |
| Manage Work Center Capacity | Standard | F3289 | CM01 / CM07 | SAP_BR_PRODN_PLANNER | work-centre load / capacity scheduling |
| Manage Bill of Operations (Routing) | Standard | CA01 | CA02 / CA03 | SAP_BR_MANUF_ENGINEER | operations ↔ work centre — makes production work-centre-wise |
| Shade Master | Master data | Fiori Elements | ZDD_SHADE | master-data role | ZDD_SHADE |
| Recipe Master | Master data | Fiori Elements | ZPP_RECEIPE | master-data role | ZRECP01/02/03 |
| Job Master | Master data | Fiori Elements | ZPP_JOBN | master-data role | ZJOB01/02/03(N) |
| Schedule Master | Master data | Fiori Elements | ZPP_SCHEDULEN | master-data role | ZSCH01/02/03(N) |
| Merge Details | Master data | Fiori Elements | ZPP_MERGE | master-data role | ZMERGE |
| Checked / Packed By | Master data | Fiori Elements | ZPP_PCBY | master-data role | ZPCBY |
| Packing Material Master | Master data | Fiori Elements | ZPACK_MAST | master-data role | ZPACK_MAST |
| Packed Stock | Analytics | ZC_PackedStockQuery | — | reporting role | 8 stock reports (ZBOXSTOCK...) |
| Packing Register | Analytics | ZC_PackingRegisterQuery | — | reporting role | 17 pack-list reports |
| WIP Batch | Analytics | ZC_WipBatchQuery | — | reporting role | ZBATCH_WIP |
| Merge Analysis | Analytics | ZC_MergeAnalysisQuery | — | reporting role | merge stock reports |
| Recipe Analysis | Analytics | ZC_RecipeAnalysisQuery | — | reporting role | ZRECPM |
| Job Card | Analytics | ZC_JobCardQuery | — | reporting role | ZJOBREPTN |

## Sales & Distribution (SD)

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| Contract Batch Update | Custom | freestyle (custom RAP) | — | custom business role | ZBATCH_CHANGE |
| Dispatch Correction | Custom | freestyle (custom RAP) | — | custom business role | ZDSP_CORR |
| Manage Sales Orders | Extended | F1873 | — | (base-app role) | ZVA01 / ZVA01N, ZSOCLOSE |
| Manage Sales Contracts | Extended | VA42 | — | (base-app role) | ZCON_CLOSE/1, ZCOREL, ZCON02 |
| Manage Outbound Deliveries | Extended | F0867A | — | (base-app role) | ZDEL |
| Release Sales Contracts | Standard | VA42 | Flexible Workflow | SAP_BR_INTERNAL_SALES_REP | contract approval — Flexible Workflow → My Inbox (cf. Manage Sales Contracts ext) |
| Sales Order Fulfillment — Issues | Standard | F0251 | VA05 | SAP_BR_INTERNAL_SALES_REP | analyse & resolve blocked / incomplete orders (ATP, credit, billing blocks) |
| Create Billing Documents | Standard | F0798 | VF01 / VF04 | SAP_BR_BILLING_CLERK | billing due list — invoice creation |
| Manage Billing Documents | Standard | F0797 | VF03 / VF05 | SAP_BR_BILLING_CLERK | review / post / cancel invoices & credit memos |
| Manage Prices — Sales | Standard | VK11 | VK11/12/13 | SAP_BR_INTERNAL_SALES_REP | pricing condition records |
| Manage Business Partner (Customer) | Standard | BP | BP / XD03 | SAP_BR_BUPA_MASTER_SPECIALIST | customer master (sales + FI-AR data) |
| Transport Code | Master data | Fiori Elements | ZTRANS | master-data role | ZTRANS |
| Export Details | Master data | Fiori Elements | ZEXP | master-data role | ZMBR2 |
| Gate Pass | Master data | Fiori Elements | ZGP_HDR / ZGP_ITEM | master-data role | ZGPS01-03, ZGPSI1-3 |
| Pending Contract | Analytics | ZC_PendingContractQuery | — | reporting role | ZPCON, ZPCOND, ZPCONS |
| Export Register | Analytics | ZC_ExportRegisterQuery | — | reporting role | ZGCUDB, ZBRC/ZEXP |
| Dispatch Register | Analytics | ZC_DispatchRegisterQuery | — | reporting role | ZPWDIS (schedule-wise) |
| Pending / Security Dispatch | Analytics | ZC_PendingDispatchQuery | — | reporting role | ZDISPATCH, ZPDESP |

## Materials & Inventory (MM)

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| HU Unpack | Custom | freestyle (custom RAP) | — | custom business role | ZHUPK |
| Inbound Delivery HUs | Custom | freestyle (custom RAP) | — | custom business role | ZHUINB |
| Post Goods Movement (HU / Box) | Custom | freestyle (custom RAP) | — | custom business role | ZBOX_MOVE |
| Compare Supplier Quotations | Standard | F2324 | ME49 | SAP_BR_PURCHASER | ZME49 |
| Manage Material Master | Standard | F1602 | MM60 | SAP_BR_BUYER | ZMM60 — incl. spare-part materials (stock / reorder / vendor) |
| Maintain Bill of Material | Standard | CS01/02/03 | IB01 (equip. BOM) | SAP_BR_MAINTENANCE_PLANNER | maintenance BOM — spare-part components list |
| Manage Purchase Requisitions | Standard | F2229 | ME51N / ME53N | SAP_BR_PURCHASER | purchase requisitions (PR) |
| Manage Purchase Orders | Standard | F0842A | ME21N / ME23N | SAP_BR_PURCHASER | create / manage POs (release = F2872) |
| Manage Purchasing Info Records | Standard | ME11 | ME11/12/13 | SAP_BR_PURCHASER | source of supply / purchasing conditions |
| Post Goods Receipt for Purchasing Doc | Standard | F0843 | MIGO | SAP_BR_WAREHOUSE_CLERK | GR against PO / inbound delivery |
| Create Supplier Invoice | Standard | F0859 | MIRO | SAP_BR_AP_ACCOUNTANT | invoice verification — 3-way match (LIV) |
| Stock — Multiple Materials | Standard | MMBE | MMBE / MB52 | SAP_BR_WAREHOUSE_CLERK | stock overview across plant / storage / batch |
| Manage Physical Inventory | Standard | MI01 | MI01/04/07 | SAP_BR_WAREHOUSE_CLERK | count sheets + post differences |
| Monitor Material Coverage (MRP) | Standard | F0247 | MD04 / MD01N | SAP_BR_MRP_CONTROLLER | MRP net requirements / shortages (uses standard Min/Max) |
| Release Purchase Orders | Standard | F2872 | ME29N | SAP_BR_PURCHASING_MANAGER | Flexible Workflow (config F2872) → approve in My Inbox (F0862) |
| Truck Master | Master data | Fiori Elements | ZTB_TRUCK_MSTR | master-data role | ZTRUCK |
| HU Inventory | Analytics | ZC_HuInventoryQuery | — | reporting role | ZHUINV_CLS |
| HU Monitor / Reconciliation | Analytics | ZC_HuMonitorQuery | — | reporting role | ZHUMO, ZHUREC |

## Quality (QM)

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| Record Inspection Results (Mass) | Custom | freestyle (custom RAP) | — | custom business role | ZQA32 |
| Master Inspection Characteristics | Standard | F2219 | QS21/22/23 | SAP_BR_QUALITY_PLANNER | MIC master (shade/denier via batch class) |
| Manage Inspection Plans | Standard | F3788 | QP01/02/03 | SAP_BR_QUALITY_PLANNER | inspection plan / task-list master |
| Manage Inspection Lots | Standard | QA32/QA33 | QA03 (display) | SAP_BR_QUALITY_ENGINEER | inspection-lot worklist — triggers results & usage decision |
| Record Inspection Results | Standard | F2170 | QE51N | SAP_BR_QUALITY_TECHNICIAN | standard results recording (your custom app = mass ZQA32 version) |
| Record Results for Inspection Points | Standard | F2689 | QE01 | SAP_BR_QUALITY_TECHNICIAN | in-process inspection points (production) |
| Manage Usage Decisions | Standard | QA11 | QA11 / QA13 | SAP_BR_QUALITY_ENGINEER | accept / reject the inspection lot |
| Manage Quality Notifications | Standard | QM01 | QM01/02/03 | SAP_BR_QUALITY_ENGINEER | customer / vendor complaints + internal quality problems |
| Create Quality Certificate (Delivery) | Standard | QC22 | QC22 / QC01 (profile) | SAP_BR_QUALITY_ENGINEER | outbound quality certificate — exports |
| Manage Quality Info Records | Standard | QI01 | QI01 / QV51 | SAP_BR_QUALITY_ENGINEER | procurement / sales quality info records |
| Manage Catalogs / Code Groups | Standard | QS41 | QS41 / QS51 | SAP_BR_QUALITY_PLANNER | defect / failure catalogs (ISO 14224 codes) |

## Finance (FI)

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| Display Line Items in G/L | Standard | F0706 | FAGLL03 | SAP_BR_GL_ACCOUNTANT | ZFBL3N / ZZFBL3N |
| Manage Customer Line Items | Standard | F0711 | FBL5N | SAP_BR_AR_ACCOUNTANT | ZFBL5N / ZZFBL5N |
| Manage Journal Entries | Standard | F0717A | FB03 | SAP_BR_GL_ACCOUNTANT | ZFB03 |
| Manage Credit Memo Requests | Standard | F0696 | VA01 (G2/L2) | SAP_BR_BILLING_CLERK | ZCRDRNOTE |
| Post Asset Acquisition | Standard | ABZON | F-90 | SAP_BR_AA_ACCOUNTANT | ZF90 |
| Maintenance Order Budget | Standard | KO22 | KO22 / cost-centre plan | SAP_BR_OVERHEAD_ACCOUNTANT | internal-order / cost-centre budget for maintenance (order costs settle here) |
| Reprocess Bank Statement Items | Standard | F1681 | FF67 | SAP_BR_CASH_SPECIALIST | ZFF67 |
| Manage Documented Credit Decisions | Standard | F5587A | FSCM-CR (DCD) | SAP_BR_CREDIT_CONTROLLER | ZCM_RELEASE — check / release / reject credit-blocked SD docs |
| Post General Journal Entries | Standard | F0718 | FB50 | SAP_BR_GL_ACCOUNTANT | manual G/L postings |
| Manage Supplier Line Items | Standard | F0712 | FBL1N | SAP_BR_AP_ACCOUNTANT | AP open / cleared items |
| Post Incoming Payments | Standard | F1345 | F-28 | SAP_BR_AR_ACCOUNTANT | AR receipts + clearing |
| Post Outgoing Payments | Standard | F1612 | F-53 | SAP_BR_AP_ACCOUNTANT | AP payments |
| Schedule Automatic Payments | Standard | F110 | F110 | SAP_BR_AP_ACCOUNTANT | automatic payment program (payment run) |
| Asset Values / Explorer | Standard | AW01N | AW01N | SAP_BR_AA_ACCOUNTANT | asset values + depreciation (Post Asset Acquisition = ABZON) |
| Trial Balance | Standard | F0996A | S_ALR / F.01 | SAP_BR_GL_ACCOUNTANT | trial balance / G/L reporting (Balance Sheet & P&L) |
| Digital Signature | Master data | Fiori Elements | ZTDIGI_SIGN | master-data role | ZDIGI |
| C-Form Allocation | Master data | Fiori Elements | ZCFORM1 | master-data role | ZCFORM1/ZFORM/ZFORMS/ZPCFORM |
| GST Tax | Analytics | ZC_GstTaxQuery | — | reporting role | ZGST, ZGST1, ZGST2, ZGSTCR |

## Maintenance (PM)

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| Request Maintenance | Standard | F1511A | IW21 (simplified) | SAP_BR_EMPLOYEE_MAINTENANCE | shop-floor maintenance request (any employee) |
| Manage Maintenance Plans | Standard | F5325 | IP01/02/03 | SAP_BR_MAINTENANCE_PLANNER | preventive plans + strategy |
| Mass Schedule Maintenance Plans | Standard | F2774 | IP30 | SAP_BR_MAINTENANCE_PLANNER | schedule due plans / deadline monitoring |
| Advanced Scheduling Board | Standard | F5460 | IW37N (order ops) | SAP_BR_MAINTENANCE_PLANNER | graphical Gantt scheduling — dispatch order operations to work centres (planner dashboard = F2227) |
| Report and Repair Malfunction | Standard | F2023 | IW21 / IW26 | SAP_BR_MAINTENANCE_TECHNICIAN | emergency malfunction report + repair |
| Manage Maintenance Notifications & Orders | Standard | F4604 | IW28 / IW38 | SAP_BR_MAINTENANCE_PLANNER | maintenance notifications + work orders |
| Breakdown Analysis (EAM KPI) | Standard | F2812 | MCI3 / MCI8 | SAP_BR_MAINTENANCE_PLANNER | downtime / MTBF / MTTR KPIs |
| Perform Maintenance Jobs | Standard | F5104A | IW41 (time conf.) | SAP_BR_MAINTENANCE_TECHNICIAN | technician executes the order — steps + time & material confirmation |
| Process Task List (Planner) | Standard | W0021 | IA05 / IA06 | SAP_BR_MAINTENANCE_PLANNER | maintenance task lists — operations behind the plans / strategies |
| Process Measuring Point | Standard | W0031 | IK01 / IK03 | SAP_BR_MAINTENANCE_TECHNICIAN | measuring points / counters — for condition & counter-based plans |
| Process Measurement Document | Standard | W0014 | IK11 / IK13 | SAP_BR_MAINTENANCE_TECHNICIAN | record meter / counter readings — drives counter-based scheduling |
| Process Technical Object | Standard | W0029 | IE01-03 / IL01-03 / IH01 | SAP_BR_MD_SPECIALIST_EAM | equipment & functional-location master (machines); display = W0028 |

## Workflow & Approvals

| App / Tile | Type | App ID | Classic tx / table | Business role | Replaces / notes |
|---|---|---|---|---|---|
| My Inbox (All Items) | Standard | F0862 | SBWP | SAP_BR_EMPLOYEE | central inbox for Flexible Workflow approvals — PO, sales contract, credit |

