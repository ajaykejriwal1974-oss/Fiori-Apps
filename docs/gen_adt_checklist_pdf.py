#!/usr/bin/env python3
"""Render the ADT activation checklist (+ dev-server runbook) as HTML -> PDF.
Mirrors docs/ADT-ACTIVATION-CHECKLIST.md; same look as the module plan."""
import html, os, glob, subprocess
from shutil import which

DATE = "26 June 2026"
def esc(s): return html.escape(str(s))

# ---- the four follow-ups, in execution order ------------------------------
FU2 = [
 "Interface CDS views <code>ZI_*</code> (over the legacy Z-tables + released <code>I_*</code> views).",
 "Projection CDS views <code>ZC_*</code> — depend on the interface views.",
 "Interface behavior definitions <code>ZI_*.bdef</code>.",
 "Behavior pool classes <code>ZBP_I_*</code> — the 13 managed masters activate cleanly; the 13 "
 "unmanaged pools must syntax-check against the release DDIC structures (this is where FU#3 bites).",
 "Projection behavior definitions <code>ZC_*.bdef</code>.",
 "Service definitions <code>ZUI_*.srvd</code> (26).",
]

VERIFY = [
 ("goods-movement-hu-rap / zbp_i_hu_item","gm_code ('04' transfer / '01' GR) + move type for the box scenario"),
 ("post-packing-gr-rap / zbp_i_post_packing_gr","GR gm_code '01' / movement type for the post-packing GR"),
 ("mtos-process-rap / zbp_i_mtos_process","BAPI_MATPHYSINV_CREATE_MULT head/item/docs structure names + head↔item linkage"),
 ("batch-status-rap / zbp_i_batch_status","ZPP_BATCHN key (BATCHNO ± GJAHR); BAPI_BATCH_CHANGE MATERIAL vs MATERIAL_LONG width"),
 ("palletization-rap / zbp_i_palletization","BAPI_HU_CREATE / BAPI_HU_PACK parameter names"),
 ("packing-detail-rap / zbp_i_packing_detail","BAPI_HU_CREATE / BAPI_HU_PACK + BAPI_HU_REPACK_ITM interface"),
 ("hu-inbound-rap / zbp_i_hu_inbound","BAPI_INB_DELIVERY_CONFIRM_DEC bapiibdlvhdrcon / bapiibdlvhdrctrlcon fields"),
 ("sales-doc-status-rap / zbp_i_sales_doc_status","contract path (BAPI_CUSTOMERCONTRACT_CHANGE alt), 'fully delivered' test, PR00 condition type"),
 ("packing-hu-rap / zbp_i_packing_unit","BAPI_HU_CREATE / BAPI_HU_PACK parameter names"),
 ("hu-unpack-rap / zbp_i_hu_unpack","BAPI_HU_UNPACK parameter names + target storage location"),
 ("qm-mass-results-rap / zbp_i_qm_inspectionchar","bapi2045d4 result-structure field names"),
 ("dispatch-correction-rap / zbp_i_dispatch_box","guard: reverse goods movement only if the box is not already invoiced/posted"),
]

# service def -> (manifest token, needs SERVICE_NS?, app)
BIND = [
 ("ZUI_HU_GOODS_MOVEMENT","REPLACE_WITH_HU_GM_SERVICE","yes","post-goods-movement-hu"),
 ("ZUI_PACKING","REPLACE_WITH_PACKING_SERVICE","yes","dyeing-packing"),
 ("ZUI_CONTRACT_BATCH","REPLACE_WITH_CONTRACT_BATCH_SERVICE","yes","contract-batch-update"),
 ("ZUI_PALLETIZATION","REPLACE_WITH_PALLETIZATION_SERVICE","yes","palletization"),
 ("ZUI_DISPATCH_CORRECTION","REPLACE_WITH_DISPATCH_CORRECTION_SERVICE","yes","dispatch-correction"),
 ("ZUI_HU_INBOUND","REPLACE_WITH_HU_INBOUND_SERVICE","yes","inbound-delivery-hus"),
 ("ZUI_PACKING_DETAIL","REPLACE_WITH_PACKING_DETAIL_SERVICE","yes","manage-packing-details"),
 ("ZUI_MTOS_PROCESS","REPLACE_WITH_MTOS_PROCESS_SERVICE","yes","mtos-process"),
 ("ZUI_HU_UNPACK","REPLACE_WITH_HU_UNPACK_SERVICE","yes","hu-unpack"),
 ("ZUI_POST_PACK_GR","REPLACE_WITH_POST_PACK_GR_SERVICE","yes","post-packing-gr"),
 ("ZUI_BATCH_STATUS","REPLACE_WITH_BATCH_STATUS_SERVICE","yes","batch-status"),
 ("ZUI_QM_INSPECTIONCHAR","REPLACE_WITH_QM_MASS_SERVICE","no (mass saver)","record-inspection-results-mass"),
 ("ZUI_SALESDOC_STATUS","REPLACE_WITH_SALESDOC_STATUS_SERVICE ×2","n/a (adaptation)","manage-sales-contracts/-orders-ext"),
 ("13 master services (ZUI_DD_SHADE, ZUI_RECIPE, …)","per-app token","no (list/object only)","13 managed-master apps"),
]

FU4 = [
 "<b>ATC</b> — run the clean-core / SAP-Cloud-Ready variant over the Z packages. Target zero P1/P2. "
 "We only consume released <code>I_*</code> CDS + released BAPIs, so released-API findings should be none — confirm.",
 "<b>DCL gap</b> — no access controls were authored (views are <code>@AccessControl.authorizationCheck:#CHECK</code>, "
 "0 <code>.dcls</code>). Author a DCL per business object, or set <code>#NOT_REQUIRED</code> with sign-off; ATC flags #CHECK without a matching DCL.",
 "<b>Fiori tiles</b> — per app, create the target mapping + tile in a business catalog and assign to the business role in PFCG (see PUBLISHING.md / ACTIVATION.md role map).",
 "<b>Adaptation projects</b> (manage-sales-contracts-ext / -orders-ext / -deliveries-ext / confirm-production-operation-ext) — "
 "fill the base-app component id / extension-point ids in the BAS Adaptation Editor against the live base apps, then deploy.",
 "<b>Smoke test</b> each tile end-to-end in the FLP (<code>/sap/bc/ui2/flp?sap-client=500</code>).",
]

# ---- dev-server runbook (condensed, activation-oriented) -------------------
RUN = [
 ("Baseline &amp; import","Confirm ADT access to the DEV system feeding KSQ/KHQ (client 500), the embedded FES is active, "
  "and the standard base apps are activated via Basis Rapid Activation. Import the repo package into a transport request.","ACTIVATION.md, TRANSPORT-PLAN.md"),
 ("Activate objects (FU#2)","Activate in dependency order: 123 ZI_*/ZC_* views → 52 behavior definitions → 28 behavior pools → 26 service definitions. "
  "Do the 13 managed masters first (no BAPI code).","backend/*"),
 ("Confirm VERIFY markers (FU#3)","As the 13 unmanaged pools activate, confirm each release-specific BAPI/DDIC name in the table below; wrong names = activation error. "
  "Smoke-test one action per BAPI family.","WIRING-CHECKLIST.md §3"),
 ("Service bindings (FU#1)","Create + activate one OData V4 binding per service definition (convention ZUI_*_O4); publish in /IWFND/V4_ADMIN. "
  "Fill the REPLACE_WITH_*_SERVICE manifest tokens and the 11 controller SERVICE_NS + 2 sales-doc SERVICE_URLs.","WIRING-CHECKLIST.md §1, §4"),
 ("ATC, DCL, tiles, go-live (FU#4)","Run ATC clean; record the DCL decision; publish tiles + assign roles; deploy the 4 adaptation projects; transport DEV → KSQ → PROD.","GO-LIVE-CHECKLIST.md, STD-RETIREMENT.md"),
]

# ---------------------------------------------------------------- build HTML
fu2 = '\n'.join(f'<li>{x}</li>' for x in FU2)
ver = '\n'.join(f'<tr><td class="mono">{esc(a) if False else a}</td><td>{b}</td></tr>' for a,b in VERIFY)
bnd = '\n'.join(f'<tr><td class="mono">{s}</td><td class="mono">{t}</td><td>{n}</td><td>{app}</td></tr>'
                for s,t,n,app in BIND)
fu4 = '\n'.join(f'<li>{x}</li>' for x in FU4)
run = '\n'.join(
 f'<div class="step"><div class="snum">{i+1}</div><div class="sbody"><h3>{t}</h3><p>{b}</p>'
 f'<p class="ref">Reference: {r}</p></div></div>' for i,(t,b,r) in enumerate(RUN))

CSS = """
@page { size:A4; margin:16mm 14mm; }
* { box-sizing:border-box; }
body { font-family:'Helvetica Neue',Arial,sans-serif; color:#1d2733; font-size:10.5pt; line-height:1.45; margin:0; }
h1 { font-size:22pt; margin:0 0 4px; color:#0a3d62; }
h2 { font-size:15pt; color:#0a3d62; border-bottom:2px solid #0a6cb0; padding-bottom:3px; margin:14px 0 8px; }
h3 { font-size:11pt; color:#0a6cb0; margin:10px 0 3px; }
p,li { margin:3px 0; } ul { margin:4px 0 8px; padding-left:18px; }
code,.mono { font-family:'SF Mono',Consolas,monospace; font-size:8.8pt; }
.lead { color:#445; } .note { color:#667; font-style:italic; font-size:9.5pt; }
.flow { background:#f6f8fa; border:1px solid #d6dee6; border-radius:5px; padding:8px 12px;
        font-family:'SF Mono',Consolas,monospace; font-size:8.8pt; white-space:pre-wrap; color:#243; }
table { width:100%; border-collapse:collapse; margin:6px 0 12px; font-size:9pt; }
th,td { border:1px solid #d6dee6; padding:4px 7px; text-align:left; vertical-align:top; }
th { background:#0a3d62; color:#fff; }
.badge { background:#0a6cb0; color:#fff; padding:1px 8px; border-radius:3px; font-size:11pt; margin-right:6px; }
.cover { text-align:center; padding-top:62mm; page-break-after:always; }
.cover .sub { font-size:13pt; color:#557; margin-top:6px; }
.cover .meta { margin-top:30mm; color:#667; font-size:10pt; }
.sec { page-break-before:always; }
.step { display:flex; gap:10px; page-break-inside:avoid; margin:8px 0; border-left:3px solid #0a6cb0; padding-left:10px; }
.snum { font-size:16pt; font-weight:bold; color:#0a6cb0; min-width:26px; }
.sbody h3 { margin-top:0; } .ref { font-size:8.6pt; color:#778; }
.foot { color:#889; font-size:8.5pt; text-align:center; margin-top:14px; border-top:1px solid #dde; padding-top:6px; }
"""

DOC = f"""<!DOCTYPE html><html><head><meta charset="utf-8"><style>{CSS}</style></head><body>
<div class="cover">
  <h1>KEJRIWAL Fiori — ADT Activation Checklist</h1>
  <div class="sub">The four system-side follow-ups + development-server runbook</div>
  <div class="sub">Clean-core extension package · KSQ/KHQ · client 500</div>
  <div class="meta">Generated {DATE} · companion to KEJRIWAL_Fiori_Module_Plan.pdf<br/>
  Repository: ajaykejriwal1974-oss/fiori-apps (merged to main) · source: docs/ADT-ACTIVATION-CHECKLIST.md</div>
</div>

<h2 style="border:none">How the four follow-ups interleave</h2>
<p class="lead">They are not four independent passes — FU#3 happens <i>inside</i> FU#2, and FU#1 depends on FU#2 finishing.
Inventory to activate: <b>123</b> CDS views, <b>52</b> behavior definitions, <b>28</b> behavior pools,
<b>26</b> service definitions (13 managed masters + 13 unmanaged transactional), 0 metadata extensions, 0 DCL.</p>
<div class="flow">FU#2  Activate CDS -&gt; BDEF -&gt; behavior pool -&gt; SRVD
        +- FU#3  Confirm VERIFY markers (surface as activation errors on the unmanaged pools)
FU#1  Create + activate service bindings, fill manifest + SERVICE_NS
FU#4  ATC clean run, then publish tiles / assign roles</div>

<h2>FU#2 — Activate the CDS / behavior / service objects (first)</h2>
<p class="lead">Activate bottom-up the first time so errors stay local:</p>
<ol>{fu2}</ol>

<h2>FU#3 — Confirm the VERIFY markers (inside FU#2)</h2>
<p class="lead">Release-specific BAPI/DDIC details CI cannot check (it validates block balance, not type names).
Each is a <code>VERIFY</code> comment in the source; wrong names fail activation on that pool.</p>
<table><tr><th>Behavior pool</th><th>Confirm</th></tr>
{ver}</table>

<div class="sec"></div>
<h2 style="border:none">FU#1 — Create + activate the OData V4 service bindings</h2>
<p class="lead">One service binding (OData V4 — UI) per service definition; activate to publish the service group.
Then set the manifest <code>dataSources.mainService.uri</code> token and, for bound-action apps, the controller
<code>SERVICE_NS</code> = the activated service definition name.</p>
<table><tr><th>Service definition</th><th>manifest token</th><th>SERVICE_NS?</th><th>App(s)</th></tr>
{bnd}</table>
<p class="note">Done when <code>grep -rn "REPLACE_WITH" apps</code> returns nothing (11 freestyle controllers + 2 sales-doc SERVICE_URLs).</p>

<h2>FU#4 — ATC clean run + Fiori tile publishing</h2>
<ul>{fu4}</ul>

<div class="sec"></div>
<h2 style="border:none">Development-server runbook (condensed)</h2>
<p class="lead">The activation sequence on DEV, end to end. The full per-step plan with all modules is in
KEJRIWAL_Fiori_Module_Plan.pdf (Part C); this is the activation-focused short form.</p>
{run}

<div class="foot">KEJRIWAL Fiori extension package · ADT activation checklist &amp; dev runbook · {DATE} ·
docs: ADT-ACTIVATION-CHECKLIST · WIRING-CHECKLIST · ACTIVATION · TRANSPORT-PLAN · GO-LIVE-CHECKLIST</div>
</body></html>"""

HTML = "/home/user/KEJRIWAL_ADT_Activation_Checklist.html"
PDF  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "KEJRIWAL_ADT_Activation_Checklist.pdf")
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
        if which(name): return which(name)
    return None

CHROME = chrome_bin()
if CHROME:
    subprocess.run([CHROME,"--headless","--no-sandbox","--disable-gpu",
                    "--no-pdf-header-footer",f"--print-to-pdf={PDF}","file://"+HTML],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("wrote PDF", PDF, os.path.getsize(PDF), "bytes")
else:
    print("no Chromium found; HTML written, render to PDF manually")
