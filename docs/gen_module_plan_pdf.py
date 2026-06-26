#!/usr/bin/env python3
"""Build the KEJRIWAL Fiori module-wise plan + dev-server runbook as HTML (->PDF)."""
import html, datetime

DATE = "26 June 2026"

def esc(s): return html.escape(str(s))

# ---- module sections (curated, accurate to the repo) -----------------------
MODULES = [
 ("SD", "Sales &amp; Distribution",
  "Sales orders, contracts, deliveries, packing, dispatch and the export/sales registers.",
  # built apps
  [("Manage Sales Orders (F1873) — adaptation", "textile custom fields + Close Order"),
   ("Manage Sales Contracts — adaptation", "Close / Complete / Release / Update-Rate"),
   ("Manage Outbound Deliveries (F0867A) — adaptation", "delivery challan via Output Mgmt"),
   ("Contract Batch Update", "mass batch assignment across contract items"),
   ("Dispatch Correction", "re-assign dispatch boxes (SO/item/status)"),
   ("Manage Packing Details", "pack / repack (ZPACK01..03N, ZREPACK)"),
   ("Dyeing Packing", "cone/carton/pallet HU structure (ZPACK*D)")],
  # backend
  [("sales-doc-status-rap", "merged VBAK service: 6 lifecycle actions (contracts + orders)"),
   ("contract-batch-rap", "BAPI_SD_SALESDOCUMENT_CHANGE (batch)"),
   ("dispatch-correction-rap", "ZSOL_HUDISPATCH ⋈ ZPP_PACK"),
   ("packing-detail-rap / packing-hu-rap", "BAPI_HU_PACK family"),
   ("transport-code-master / truck-master / export-detail-master", "managed RAP over ZTRANS / ZTB_TRUCK_MSTR / ZEXP")],
  # BI
  ["Sales Register", "Packing / Dispatch Register", "Export Register", "Dispatch Register", "Pending Contract Register"],
  # reuse / standard
  "Sales-register variants → 1 query; ZVA01/N custom fields via key-user adaptation; reuse ZSOL_SALCONT_CDS / ZSOL_F4* value helps.",
  "ZVA01/N, ZSOCLOSE(1), ZCON_CLOSE/CLOSE1/COREL/CON02, ZDEL/ZDELC, ZBATCH_CHANGE, ZDSP_CORR, ZPLIST*/ZPACK*, ZSALES*, ZSOREG, ZGCUDB/ZBRC/ZEXP"),

 ("PP", "Production Planning",
  "Dyeing production entry, batches, job cards, schedules, recipes, merge, palletization and the production/stock analytics.",
  [("Confirm Production Operation (F3069) — adaptation", "dyeing production entry (ZCO11N/A)"),
   ("Palletization", "pack boxes on pallet (ZPALLET/1, ZPAL_BOX)"),
   ("Post Packing &amp; GR", "post packing + goods receipt (ZPOST01)"),
   ("Batch Status", "close / delete batch (ZBATCHD, ZBATCH_CLS)")],
  [("recipe / job / schedule / merge / checked-by / packing-material masters", "managed RAP over the real ZPP_* tables"),
   ("shade-master-rap", "reference managed CBO (ZDD_SHADE)"),
   ("gate-pass-rap", "managed RAP composition ZGP_HDR → ZGP_ITEM"),
   ("batch-status / palletization / post-packing-gr", "unmanaged RAP action services")],
  ["Packed-Stock Analysis (8 reports → 1)", "WIP Batch", "Job Card", "Recipe Analysis", "Merge Analysis"],
  "Create/Change/Display master variants collapse into one Fiori Elements app each; recipe/job-card PRINT becomes an Output-Management form on the master.",
  "ZCO11N/A, ZRECP*, ZJOB*, ZSCH*, ZBATCH* (master/del/close/WIP), ZMERGE, ZPALLET*, ZPOST01, ZREPACK, ZPRP*, ZLABEL, ZPCBY"),

 ("MM", "Materials Management &amp; Handling Units",
  "Handling-unit handling, goods movement, gate pass, purchasing automation, MTO→MTS and stock.",
  [("Post Goods Movement (HU / Box)", "box/HU-wise movement (ZBOX_MOVE)"),
   ("Inbound Delivery HUs", "post inbound GR (ZHUINB)"),
   ("HU Unpack", "RM unpack (ZHUPK)"),
   ("MTOS Process", "MTO→MTS transfer + phys-inv doc (ZMTOS+ZHUINV, merged)")],
  [("goods-movement-hu / hu-inbound / hu-unpack / mtos-process", "unmanaged RAP over standard HU (VEKP/VEPO)"),
   ("hu-shared", "shared ZI_HU_ItemBase / ZI_HU_HeaderBase (used by 7 services)"),
   ("gate-pass-rap", "the custom gate-pass object (also serves MM inward/outward)"),
   ("po-automation / obd-automation", "ABAP job classes: PO &amp; delivery automation"),
   ("minmax-master-rap", "reuse standard MRP on MARC (stub)")],
  ["HU Inventory Analysis (ZHUMO/ZHUREC/ZHUINV_CLS → 1)"],
  "Generic stock (ZMB5B/ZCMM001/ZBSTOCK) → standard inventory apps; ZAUTOPO* (9) → one PO-automation class; reuse ZSOL_INBOUND_HU / ZSOL_POST_GOODS_MOVEMENTS / ZSOL_PALLETIZATION.",
  "ZBOX_MOVE, ZHUINB, ZHUPK, ZHUINV, ZMTOS, ZGP*/ZGATE* (gate pass), ZAUTOPO*, ZME49, ZMM60, ZPR, ZRFQ, ZWMTO_UPLD, ZMB5B/ZBSTOCK"),

 ("QM", "Quality Management",
  "Mass inspection-result recording and inspection-lot handling.",
  [("Record Inspection Results (Mass)", "multi-lot result entry (ZQA32) — vs F2655 one-lot")],
  [("qm-mass-results-rap", "reads standard QM (QAMV/QALS/QAPO/QAMR); posts via QM result API")],
  [],
  "ZINSPLOT may map to standard Create Inspection Lot; ZQAR (cancel lot) and ZQ_FORM (cert) → standard + Output Management.",
  "ZQA32, ZINSPLOT, ZQAR, ZQ_FORM"),

 ("FI", "Financial Accounting &amp; Compliance",
  "Line-item display, ageing, statements, GST/TDS, banking, assets, C-Form, Bill of Exchange and posting automation.",
  [("(no custom Fiori app — see masters &amp; reuse)", "FI is mostly standard apps + automation")],
  [("cform-master-rap", "C-Form allocation (ZCFORM1) — pending↔received"),
   ("digital-signature-master-rap", "ZTDIGI_SIGN configuration"),
   ("bill-of-exchange-std", "reuse standard FI Bill of Exchange (stub)"),
   ("po-automation (FI posting variants)", "F-02 BDC clones → Journal Entry API")],
  ["Ageing", "Account Statement", "Interest", "TDS", "GST Tax Register", "Commission", "Credit/Debit Note"],
  "Line-item apps (FBL3N/5N), cheque (Check Mgmt), Bill of Exchange (F-36/F-33/FBW*), GST/excise (DRC) all reuse STANDARD; FI uploads → Migration Cockpit / Journal Entry API; all BDC retired.",
  "ZFBL3N/5N, ZF02/ZFIEX/ZFIVT, ZFI* (ageing/stmt/interest/TDS), ZGST*, ZCHQ, ZABMA, ZCFORM*, ZBOE, ZCRDR*, ZBANK"),

 ("CROSS", "Cross-application / Platform / Compliance",
  "Document &amp; Reporting Compliance (e-invoice/e-way), Output Management, data migration and platform utilities.",
  [("(platform / config — not Fiori tiles)", "")],
  [("DRC (India e-invoice / e-way)", "ZEINV*/ZEWAY*/ZEXN → standard SAP DRC (excluded from build)"),
   ("Output Management (PRT layer, 61)", "forms/labels/stickers/gate-pass print → BRF+ + Adobe templates"),
   ("Data migration (UPL layer, 28)", "uploads → Migration Cockpit; automation → APIs / Application Jobs"),
   ("digital signature / PDF / task list / audit log", "platform utilities")],
  [],
  "DRC replaces the entire e-invoice/e-way family; PRT → Output Management; UPL → Migration Cockpit + public APIs (BDC retired).",
  "ZEINV*, ZEWAY*, ZEXN, ZPDF, ZDIGI, ZTASKLIST, ZAUDIT_LOG, + 61 PRT + 28 UPL programs"),
]

# ---- deliverable register (module-wise, code -> replaced Z-tcodes) ----------
# Type: ADAPT = key-user adaptation of a standard app; APP = custom Fiori app;
#       RAP-M = managed-RAP master (Fiori Elements from service binding);
#       REPORT = analytical CDS query (List Page / Query Browser).
# 'replaces' is the COMPLETE Z-tcode set per code (authoritative: docs/CLASSIFICATION.md
# §"How the custom builds map" + docs/BI-CONSOLIDATION.md families). †=retired duplicate.
REGISTER = [
 ("SD","Sales &amp; Distribution",[
   ("SD-01","Manage Sales Orders (adaptation, F1873)","ADAPT","ZVA01, ZVA01N, ZSOCLOSE, ZSOCLOSE1"),
   ("SD-02","Manage Sales Contracts (adaptation)","ADAPT","ZCON_CLOSE, ZCON_CLOSE1, ZCOREL, ZCON02"),
   ("SD-03","Manage Outbound Deliveries (adaptation, F0867A)","ADAPT","ZDEL, ZDELC"),
   ("SD-04","Contract Batch Update","APP","ZBATCH_CHANGE"),
   ("SD-05","Dispatch Correction","APP","ZDSP_CORR"),
   ("SD-06","Manage Packing Details","APP","ZPACK01, ZPACK01N, ZPACK02, ZPACK02N, ZPACK03, ZREPACK"),
   ("SD-07","Dyeing Packing","APP","ZPACK01D, ZPACK02D, ZPACK03D, ZREPACKD"),
   ("SD-08","Transport Code Master","RAP-M","ZTRANS"),
   ("SD-09","Truck Master","RAP-M","ZTRUCK"),
   ("SD-10","Export Details Master","RAP-M","ZMBR2"),
   ("SD-R1","Packing / Dispatch Register (17 → 1)","REPORT",
    "ZPACKLIST, ZPACKLIST01, ZPACKLISTN, ZPLIST01, ZPLIST01A, ZPLIST01T, ZPLIST02, ZPLIST02A, "
    "ZPLIST02N†, ZPLIST02T, ZPLIST03, ZPLIST03A, ZPLIST03N†, ZPLIST03T, ZPLISTD, ZPLISTDA, ZPLISTDT"),
   ("SD-R2","Dispatch Register","REPORT","ZPWDIS, ZDISPATCH, ZPDESP, ZSCAND"),
   ("SD-R3","Export / Incentive Register","REPORT","ZGCUDB, ZBRC, ZEXP"),
   ("SD-R4","Pending Contract Register","REPORT","ZPCON, ZPCOND, ZPCONS, ZPCON_CP†"),
 ]),
 ("PP","Production Planning",[
   ("PP-01","Confirm Production Operation (adaptation, F3069)","ADAPT","ZCO11N, ZCO11A"),
   ("PP-02","Palletization","APP","ZPALLET, ZPALLET1, ZPAL_BOX, ZSOL_ASRS"),
   ("PP-03","Post Packing &amp; GR","APP","ZPOST01"),
   ("PP-04","Batch Status","APP","ZBATCHD, ZBATCH_CLS"),
   ("PP-05","Recipe Master","RAP-M","ZRECP01, ZRECP02, ZRECP03"),
   ("PP-06","Job Master","RAP-M","ZJOB01, ZJOB01N, ZJOB02, ZJOB02N, ZJOB03, ZJOB03N"),
   ("PP-07","Schedule Master","RAP-M","ZSCH01, ZSCH01N, ZSCH02, ZSCH02N, ZSCH03, ZSCH03N"),
   ("PP-08","Merge Details Master","RAP-M","ZMERGE"),
   ("PP-09","Checked / Packed-By Master","RAP-M","ZPCBY"),
   ("PP-10","Packing Material Master","RAP-M","ZPACK_MAST"),
   ("PP-11","Shade Master (Dope Dyeing)","RAP-M","ZDD_SHADE"),
   ("PP-R1","Packed-Stock Analysis (8 → 1)","REPORT",
    "ZBOXSTOCK, ZGSTOCK, ZPRP1, ZSSTOCK, ZDSTOCK, ZSTOCK, ZPRP, ZPRPSZ"),
   ("PP-R2","WIP Batch","REPORT","ZBATCH_WIP"),
   ("PP-R3","Job Card Report","REPORT","ZJOBREPTN, ZJOBREPORT†"),
   ("PP-R4","Recipe Master Report","REPORT","ZRECPM"),
   ("PP-R5","Merge Analysis","REPORT","new analytics over ZPP_MERGE (Merge master; no standalone legacy report)"),
 ]),
 ("MM","Materials Management &amp; Handling Units",[
   ("MM-01","Post Goods Movement (HU / Box)","APP","ZBOX_MOVE"),
   ("MM-02","Inbound Delivery HUs","APP","ZHUINB"),
   ("MM-03","HU Unpack","APP","ZHUPK"),
   ("MM-04","MTOS Process","APP","ZMTOS, ZHUINV"),
   ("MM-05","Gate Pass","RAP-M","ZGPS01, ZGPS02, ZGPS03, ZGPSI1, ZGPSI2, ZGPSI3"),
   ("MM-R1","HU Inventory Analysis","REPORT","ZHUMO, ZHUREC, ZHUINV_CLS"),
 ]),
 ("QM","Quality Management",[
   ("QM-01","Record Inspection Results (Mass)","APP","ZQA32"),
 ]),
 ("FI","Financial Accounting &amp; Compliance",[
   ("FI-01","C-Form Allocation Master","RAP-M","ZCFORM1, ZFORM, ZFORMS, ZPCFORM"),
   ("FI-02","Digital Signature Master","RAP-M","ZDIGI"),
   ("FI-R1","GST Tax Register","REPORT","ZGST, ZGST1, ZGST2, ZGSTCR"),
 ]),
]

# ---- dev-server runbook (ordered) ------------------------------------------
STEPS = [
 ("Prerequisites &amp; baseline",
  "Confirm ADT access to the DEV system feeding KSQ/KHQ (client 500), the embedded Front-End Server is active, and the standard base apps (F1873, F3069, F0867A, Manage Sales Contracts, F2655, MIGO/HU) are activated via Basis Rapid Activation. Import the repo objects into a development package + transport request (see TRANSPORT-PLAN.md).",
  "ACTIVATION.md, TRANSPORT-PLAN.md"),
 ("Activate the managed-RAP masters first (lowest effort)",
  "For each master (Recipe, Job, Schedule, Transport, Truck, Merge, Checked-by, Packing-Material, Export, Digital-Signature, C-Form, Shade, Gate Pass): confirm the underlying legacy table exists (all bind EXISTING tables; only ZDD_SHADE may need its table created), then activate the CDS interface → projection → behavior definition → behavior class → metadata extension → service definition. Create the OData V4 service binding (e.g. ZUI_RECIPE_O4) and publish it.",
  "backend/*-master-rap, backend/gate-pass-rap"),
 ("Generate &amp; test the master Fiori Elements apps",
  "Each master's List Report / Object Page is generated from its .ddlx via the service binding — no UI code. Launch from the binding preview, verify the field list against the live data, then wire the Gate-Pass number range (ZGPASS_NUM) in setHeaderDefaults and reuse ZSOL_F4* value helps.",
  "WIRING-CHECKLIST.md §1, §5"),
 ("Wire the adaptation projects (SD + PP)",
  "For the 4 adaptation projects, fill the base-app identifiers from the activated standard apps: REPLACE_WITH_BASE_APP_COMPONENT_ID / BSP_NAME / FIORI_ID / OBJECT_PAGE_VIEW_ID / CONTROLLER_NAME / EXTENSION_POINT_NAME. Deploy the app-variant; confirm the custom section/column/controller extension renders on the standard app.",
  "apps/manage-sales-orders-ext, manage-sales-contracts-ext, manage-outbound-deliveries-ext, confirm-production-operation-ext"),
 ("Implement the unmanaged transactional services (the BAPI bodies)",
  "For each transactional service, replace the TODO in the behavior class with the real BAPI call: sales-doc-status → BAPI_SD_SALESDOCUMENT_CHANGE; mtos-process → BAPI_GOODSMVT_CREATE + BAPI_MATPHYSINV_CREATE_MULT; packing/HU → BAPI_HU_PACK/_REPACK/_UNPACK/_CREATE; goods-movement → BAPI_GOODSMVT_CREATE; hu-inbound → BAPI_INB_DELIVERY_CONFIRM_DEC; batch-status → BAPI_BATCH_CHANGE; dispatch-correction → ZSOL_DISPATCH_CORRECTION; qm-mass-results → QM result API. Add BAPI_TRANSACTION_COMMIT and map the BAPI return into reported/failed. Resolve the 5 VERIFY markers (release-specific filters).",
  "WIRING-CHECKLIST.md §3, REUSE-EXISTING.md"),
 ("Create the service bindings &amp; wire the freestyle apps",
  "Create the OData V4 binding for each transactional service (ZUI_*_O4) and put the name into each app's manifest.json (REPLACE_WITH_*_SERVICE) and the two adaptation controllers (REPLACE_WITH_SALESDOC_STATUS_SERVICE). Then wire the front-end action invocation (oOperation.invoke() with the parameter structure) in the 12 worklist/controller TODOs; set REPLACE_WITH_ABAP_SYSTEM_URL in each ui5.yaml for local test.",
  "WIRING-CHECKLIST.md §1, §4"),
 ("Build the analytical queries (BI)",
  "Activate the 11 CDS cube/query pairs in backend/analytics. Switch @AccessControl.authorizationCheck from #NOT_REQUIRED to #CHECK with a DCL. Expose each ZC_*Query via the Query Browser or an Analytical List Page; add the secondary-object joins noted (billing tax amounts, contract value, dispatch weight). Map the retired report users to the new query + role.",
  "backend/analytics, BI-CONSOLIDATION.md"),
 ("Register the automation jobs (UPL)",
  "Activate ZCL_PO_AUTOMATION and ZCL_OBD_AUTOMATION; complete the API calls and the Application-Job parameter definitions; register each as an Application Job catalog entry and schedule it (VKORG / WERKS parameters). Build the remaining UPL items as Migration Cockpit objects / standard API clients — retire all BDC.",
  "backend/po-automation, backend/obd-automation, UPL-MIGRATION.md"),
 ("Output Management &amp; statutory (PRT + DRC)",
  "Re-platform the 61 PRT programs onto Output Management: one BRF+ determination + Adobe form template per output object (billing, delivery, gate pass, labels). Configure standard SAP DRC for India e-invoice / e-way bill (the excluded ZEINV* family). Retire the pre-GST 201-series and RG1 forms.",
  "PRT-OUTPUT-MANAGEMENT.md"),
 ("Retire the STD &amp; reuse items; assign roles",
  "Assign the 17 STD standard apps + the reuse-standard items (Min/Max on MARC, Bill of Exchange, generic stock, ageing/statements) to the relevant SAP_BR_* business roles; publish tiles in the users' Spaces/Pages; retire the corresponding Z transactions after a parallel run.",
  "STD-RETIREMENT.md, REUSE-EXISTING.md"),
 ("Validate, transport, go-live",
  "Run ATC on every activated object, execute the per-app GO-LIVE-CHECKLIST, then transport DEV → KSQ → PROD per the TRANSPORT-PLAN. The repo's structural CI (ci/validate.py) gates JSON/XML/CDS/ABAP structure on each change.",
  "GO-LIVE-CHECKLIST.md, TRANSPORT-PLAN.md, ci/validate.py"),
]

COVERAGE = [("CUS",72,"Built (masters + transactional) or reuse / DRC excluded"),
            ("EXT",19,"Built / wired into adaptations"),
            ("STD",17,"Standard Fiori app + business role"),
            ("PRT",61,"Output Management (gate pass built)"),
            ("BI",87,"Consolidated → ~31; 11 CDS queries built"),
            ("UPL",28,"Migration Cockpit / APIs; 2 automation classes built"),
            ("RET",1,"Retire")]

# ---------------------------------------------------------------- build HTML
def section(m):
    code,name,intro,apps,be,bi,reuse,tcodes = m
    h=[f'<section class="mod"><h2><span class="badge">{code}</span> {name}</h2>',
       f'<p class="intro">{intro}</p>']
    if apps and apps[0][0].startswith('('):
        h.append(f'<p class="note">{apps[0][0]} {apps[0][1]}</p>')
    elif apps:
        h.append('<h3>Apps built</h3><ul>')
        for a,d in apps: h.append(f'<li><b>{a}</b> — {d}</li>')
        h.append('</ul>')
    h.append('<h3>Backend (RAP / classes)</h3><ul>')
    for a,d in be: h.append(f'<li><b>{a}</b> — {d}</li>')
    h.append('</ul>')
    if bi:
        h.append('<h3>Analytics</h3><p>'+' · '.join(f'<span class="pill">{x}</span>' for x in bi)+'</p>')
    h.append(f'<h3>Reuse / standard</h3><p>{reuse}</p>')
    h.append(f'<h3>Representative Z-tcodes</h3><p class="codes">{tcodes}</p>')
    h.append('</section>')
    return '\n'.join(h)

TYPE_LABEL = {"ADAPT":"Adaptation","APP":"Custom app","RAP-M":"Master (RAP)","REPORT":"Report"}

def register_block(reg):
    code,name,rows = reg
    h=[f'<div class="mod"><h3><span class="badge sm">{code}</span> {name}</h3>',
       '<table class="reg"><tr><th>Code</th><th>App / Report</th><th>Type</th>'
       '<th>Replaces (Z-tcodes)</th></tr>']
    for c,d,t,rep in rows:
        h.append(f'<tr><td class="rc">{c}</td><td>{d}</td>'
                 f'<td class="rt">{TYPE_LABEL.get(t,t)}</td><td class="codes inl">{rep}</td></tr>')
    h.append('</table></div>')
    return '\n'.join(h)

import re as _re
n_apps=sum(1 for _,_,rows in REGISTER for c,d,t,rep in rows if t in ("ADAPT","APP","RAP-M"))
n_rep =sum(1 for _,_,rows in REGISTER for c,d,t,rep in rows if t=="REPORT")
_alltc=set()
for _,_,rows in REGISTER:
    for c,d,t,rep in rows:
        for tc in _re.findall(r'\bZ[A-Z0-9_]{2,}', rep): _alltc.add(tc)
n_tc=len(_alltc)
reg_html='\n'.join(register_block(r) for r in REGISTER)
cov_rows='\n'.join(f'<tr><td class="c">{c}</td><td class="n">{n}</td><td>{d}</td></tr>' for c,n,d in COVERAGE)
mod_html='\n'.join(section(m) for m in MODULES)
step_html='\n'.join(
 f'<div class="step"><div class="snum">{i+1}</div><div class="sbody"><h3>{t}</h3><p>{b}</p>'
 f'<p class="ref">Reference: {r}</p></div></div>'
 for i,(t,b,r) in enumerate(STEPS))

CSS = """
@page { size: A4; margin: 16mm 14mm; }
* { box-sizing: border-box; }
body { font-family: 'Helvetica Neue', Arial, sans-serif; color:#1d2733; font-size:10.5pt; line-height:1.45; margin:0; }
h1 { font-size:23pt; margin:0 0 4px; color:#0a3d62; }
h2 { font-size:15pt; color:#0a3d62; border-bottom:2px solid #0a6cb0; padding-bottom:3px; margin:0 0 8px; }
h3 { font-size:11pt; color:#0a6cb0; margin:11px 0 3px; }
.intro { color:#445; margin:0 0 6px; }
.note { color:#667; font-style:italic; }
ul { margin:3px 0 6px; padding-left:18px; }
li { margin:2px 0; }
.badge { background:#0a6cb0; color:#fff; padding:1px 8px; border-radius:3px; font-size:12pt; margin-right:6px; }
.pill { background:#eef4fa; border:1px solid #cfe0ef; border-radius:10px; padding:1px 8px; font-size:9pt; white-space:nowrap; display:inline-block; margin:2px 1px; }
.codes { font-family:'SF Mono',Consolas,monospace; font-size:8.6pt; color:#334; background:#f6f8fa; padding:6px 8px; border-radius:4px; }
table { width:100%; border-collapse:collapse; margin:6px 0 10px; font-size:9.6pt; }
th,td { border:1px solid #d6dee6; padding:4px 7px; text-align:left; vertical-align:top; }
th { background:#0a3d62; color:#fff; }
td.c { font-weight:bold; color:#0a6cb0; width:48px; } td.n { text-align:right; width:42px; font-weight:bold; }
.badge.sm { font-size:9.5pt; padding:0 6px; }
table.reg { font-size:9pt; margin:4px 0 12px; }
table.reg td.rc { font-family:'SF Mono',Consolas,monospace; font-weight:bold; color:#0a3d62; width:46px; white-space:nowrap; }
table.reg td.rt { width:78px; color:#557; }
.codes.inl { padding:2px 6px; font-size:8.4pt; }
.cover { text-align:center; padding-top:60mm; page-break-after:always; }
.cover .sub { font-size:13pt; color:#557; margin-top:6px; }
.cover .meta { margin-top:30mm; color:#667; font-size:10pt; }
.mod { page-break-inside:avoid; margin-bottom:14px; }
.sec { page-break-before:always; }
.step { display:flex; gap:10px; page-break-inside:avoid; margin:8px 0; border-left:3px solid #0a6cb0; padding-left:10px; }
.snum { font-size:16pt; font-weight:bold; color:#0a6cb0; min-width:26px; }
.sbody h3 { margin-top:0; }
.ref { font-size:8.6pt; color:#778; }
.lead { color:#445; }
.foot { color:#889; font-size:8.5pt; text-align:center; margin-top:14px; border-top:1px solid #dde; padding-top:6px; }
"""

DOC = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>
<div class="cover">
  <h1>KEJRIWAL Z-Portfolio → SAP S/4HANA 2025 Fiori</h1>
  <div class="sub">Module-wise build inventory &amp; development-server runbook</div>
  <div class="sub">Clean-core extension package · KSQ/KHQ · client 500</div>
  <div class="meta">Generated {DATE} · All 285 Z-transactions classified &amp; routed<br/>
  Repository: ajaykejriwal1974-oss/fiori-apps (merged to main)</div>
</div>

<section>
<h2>Executive summary</h2>
<p class="lead">The entire custom Z-portfolio — <b>285 transactions</b> — has been classified, routed
clean-core (no SAP source modified), and for everything that warrants custom code, scaffolded with
real fields from the field dictionary. This document lists the work <b>by SAP module</b> and gives a
<b>step-by-step plan for the development server</b>.</p>
<table>
<tr><th>Class</th><th>Count</th><th>Disposition</th></tr>
{cov_rows}
</table>
<p class="note">Clean core throughout: key-user / adaptation / RAP / released-API only — never a modification.
Module grouping below is functional; textile logistics (packing / HU / gate pass) legitimately spans PP, MM and SD.</p>
</section>

<div class="sec"></div>
<h2 style="border:none">Part A — Deliverable register (module-wise, by code)</h2>
<p class="lead">Every app, master and report built in this package, grouped by SAP module, each with a
<b>delivery code</b> and its <b>complete set</b> of replaced Z-transactions (expanded from
<code>docs/CLASSIFICATION.md</code> + <code>docs/BI-CONSOLIDATION.md</code>, not just the
representative tcode). <b>{n_apps}</b> apps/masters (<code>-NN</code>), <b>{n_rep}</b> analytical
reports (<code>-RN</code>), <b>{n_tc}</b> distinct Z-tcodes covered. Type:
<i>Adaptation</i> = key-user extension of a standard app; <i>Custom app</i> = freestyle SAPUI5;
<i>Master (RAP)</i> = managed-RAP Fiori Elements; <i>Report</i> = analytical CDS query.
<code>†</code> = retired duplicate folded into the consolidated query.</p>
{reg_html}

<div class="sec"></div>
<h2 style="border:none">Part B — Build inventory by module</h2>
{mod_html}

<div class="sec"></div>
<h2 style="border:none">Part C — Next steps on the development server (in order)</h2>
<p class="lead">Each step is a stage of activation/wiring on DEV. Earlier steps unblock later ones;
masters need the least wiring, the transactional BAPI bodies the most. References point to the repo docs.</p>
{step_html}

<div class="foot">KEJRIWAL Fiori extension package · module-wise plan &amp; dev runbook · {DATE} ·
docs: CLASSIFICATION · WIRING-CHECKLIST · ACTIVATION · TRANSPORT-PLAN · GO-LIVE-CHECKLIST</div>
</body></html>"""

import os, subprocess, glob
HTML = "/home/user/KEJRIWAL_Fiori_Module_Plan.html"
PDF  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "KEJRIWAL_Fiori_Module_Plan.pdf")
open(HTML,"w").write(DOC)
print("wrote HTML", len(DOC), "bytes")

def chrome_bin():
    env = os.environ.get("CHROME_BIN")
    if env and os.path.exists(env): return env
    for pat in ("/opt/pw-browsers/chromium-*/chrome-linux/chrome",
                "/opt/pw-browsers/chromium_headless_shell-*/chrome-linux/headless_shell"):
        hits = sorted(glob.glob(pat))
        if hits: return hits[-1]
    for name in ("google-chrome","chromium","chromium-browser"):
        from shutil import which
        if which(name): return which(name)
    return None

CHROME = chrome_bin()
if CHROME:
    subprocess.run([CHROME,"--headless","--no-sandbox","--disable-gpu",
                    "--no-pdf-header-footer",f"--print-to-pdf={PDF}",
                    "file://"+HTML], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("wrote PDF", PDF, os.path.getsize(PDF), "bytes")
else:
    print("no Chromium found; HTML written, render to PDF manually")
