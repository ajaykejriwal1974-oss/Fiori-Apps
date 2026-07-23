# Phase 4 — Document & Reporting Compliance (DRC) adoption

23 Jul 2026. **This is a configuration + compliance project, not a development
build.** The goal is to retire the custom India e-invoice / e-way-bill cockpit and
excise registers and move to the **standard S/4HANA 2025 DRC + eDocument** solution
(SAP-delivered, statutory-maintained, no custom code). Owned jointly by the **tax
team** (compliance) and **Basis** (config + connectivity). Do NOT rebuild any of the
below as custom Fiori apps.

## What is retired (≈19 custom transactions + their tables)

### E-Invoice / E-Way-Bill custom cockpit → standard DRC/eDocument
| Custom tcode | Program | Standard replacement |
|---|---|---|
| `ZEINV` | ZEINV_COCKPIT (cockpit) | **eDocument Cockpit** (`EDOC_COCKPIT`) / **Manage Compliance Documents** (DRC) |
| `ZEINV_EXT` | ZEINV_EXTRACT | Automatic eDocument creation on billing (no manual extract) |
| `ZEINV_CANC` | ZEINV_CANC | Cancel from the eDocument cockpit |
| `ZEINV_EWAY_BY_IRN` | ZEINV_EWAY_USING_IRN | Standard e-Way-Bill-from-IRN step in the India eInvoice process |
| `ZEWAY_CANC` | ZEWAY_CANC | e-Way cancel in the cockpit |
| `ZEINV_UPDATE` / `ZEINV_UPLOAD` / `ZEINV_UPGRADE` | excel/IRN upload, FY update | Not needed — DRC posts IRN/EWB back automatically via the API |
| `ZEINV_SETUP` | ZEXIM_COCKPIT_NEW | Standard eDocument/DRC customizing (SPRO) |
| `ZEINV_CO_CODE` / `ZEINV_DOCTYP` / `ZEINV_STATE_CODE` / `ZEINV_UOM` / `ZEINV_LOGIN` | custom config/master | Standard eDocument config + IRP credentials in connectivity setup |
| `ZAUDIT_LOG` (+ table `ZEINV_AUDITLOG`) | audit report | eDocument **status/history** is standard (the Phase-3 `ZC_AUDIT_LOG` query can bridge legacy data during parallel run) |

Custom tables retired: `ZEINV_AUDITLOG`, `ZEINV_LOGIN`, `ZEINV_CO_CODE`, `ZEINV_DOCTYP`,
`ZEINV_STATE_CODE`, `ZEINV_UOM` (kept read-only until the parallel run is signed off).

### Excise registers (ride along)
| Custom tcode | Was | Decision |
|---|---|---|
| `ZRG1` / `ZRG1N` / `ZRG1TEX` | RG1 excise register | **Retire** — central excise was subsumed by GST (2017); RG1 is legacy unless a still-excisable product exists. Confirm with tax; if any excisable line remains, use DRC statutory reporting. |
| `ZJ1IIN` (ZSD_EXCISE_AUTOMATE) | auto excise invoice | Retire with the excise registers (GST regime). |
| `ZPUREG` | Purchase register | GSTR-2 aligned — use **DRC GSTR reporting** / a standard purchase register query. |

## The standard solution (what to adopt)

**India eInvoicing + eWay Bill** run on the **eDocument framework**, surfaced/managed
through **DRC (Document & Reporting Compliance)** in S/4HANA 2025:
- On billing (VF01/VF03), an **eDocument** is created automatically for the invoice.
- It is submitted to the government **IRP (Invoice Registration Portal)** through a
  connector, which returns the **IRN + signed QR + (optionally) the eWay Bill**.
- Status, resubmission, and cancellation are handled in the **eDocument Cockpit /
  Manage Compliance Documents** — no custom cockpit.
- SAP delivers and **maintains** the India legal content (schema/API changes) as a
  compliance service, so future statutory changes are vendor-handled.

## Setup checklist (Basis + tax, config only)

1. **Prerequisites / connectivity**
   - Activate the **eDocument** and **DRC** frameworks (SPRO: Cross-Application
     Components → General Application Functions → Document and Reporting Compliance).
   - Establish IRP connectivity: via **SAP Localization Hub, digital compliance
     service for India** or a **GSP/ASP** connector (the legal gateway to the
     government IRP). This replaces the custom API integration in `ZEINV`.
   - Digital signature / API credentials per **GSTIN** (was `ZEINV_LOGIN`).
2. **eDocument process config**
   - Activate the **source type** (SD billing) and **eDocument type** for India
     eInvoice + eWay Bill; assign to company codes / billing types (was
     `ZEINV_CO_CODE` / `ZEINV_DOCTYP`).
   - Interface type / communication (SOAP/REST to the connector).
   - Number ranges, UoM & state-code mapping to the government code lists (was
     `ZEINV_UOM` / `ZEINV_STATE_CODE`).
3. **Roles**
   - Assign **`SAP_BR_...` DRC/compliance roles** (e.g. tax specialist) so the
     **eDocument Cockpit / Manage Compliance Documents / Run Compliance Reports**
     apps appear in the FLP (same role-copy pattern as the Phase 1 Basis doc).
4. **Cutover & parallel run (with tax team)**
   - Pick a cutover date; freeze new `ZEINV` usage after it.
   - Run DRC eInvoicing in **parallel** on a sample of live invoices; reconcile IRN /
     eWay numbers against the legacy `ZEINV_AUDITLOG` (via the Phase-3 audit query).
   - Sign-off → switch off `ZEINV*` tcodes; keep the custom tables read-only for the
     statutory retention period, then archive.

## Verified IMG sequence on KSD (23 Jul 2026)

Confirmed live: eDocument framework installed, India eInvoice solution present
(`CL_EDOCUMENT_IN_EINV`), but **nothing activated** (EDOC_COCKPIT → "no active source
types in EDOCOMPANYACTIV"). The standard India DRC IMG is fully delivered at:

**SPRO → Cross-Application Components → General Application Functions → Document and
Reporting Compliance → Country/Region-Specific Settings → India**

**A. Electronic Document Processing** (eInvoice + eWay — do in this order)
1. `General Settings`
2. `Settings for Electronic Invoicing` (IRN)
3. `Settings for Electronic Way Bill`
4. `Settings for Source Reference for GST Reporting`
5. `Consistency Check Settings`
Plus the framework-level activation under **Set Up Document and Reporting Compliance**
(eDocument type → assign to source type SD billing → **Activate Source Type for
Company Code** = the live switch) and the **interface/web-service** to the GSP/IRP.

**B. Statutory Reporting** (GST returns + TDS)
- `GSTR 1 Report`, `GSTR 3B Report`, `GSTR 6 Report`
- `Withholding Tax Report` (replaces ZFI_TDS/ZQTDS; supersedes the Phase-3 ZC_TDS query)
- `FORM GST ANX1 Report`, `FORM GST ANX2 Report`

> **Execution rule (client 500 = PRODUCTION):** build/validate this config on a
> non-prod/sandbox client with the IRP **sandbox** endpoint, get tax sign-off, then
> transport to 500 and do "Activate Source Type for Company Code" at a planned
> cutover. Do NOT configure/activate directly in 500. The **GSP/IRP connectivity**
> (GSP contract + API credentials, or SAP Localization Hub) is the external
> prerequisite for step A3/interface — without it, nothing transmits.

## Effort & ownership
Separate **compliance project** (weeks, tax-team-led config + testing), not part of
the app-build track. No ABAP. Companion: this doc + the Phase-3 `ZC_AUDIT_LOG` query
(bridges legacy audit data during the parallel run). Confirm the RG1/excise decision
with tax before retiring those registers.
