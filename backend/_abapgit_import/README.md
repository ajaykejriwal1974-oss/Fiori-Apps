# abapGit import — KGPL RAP backend (master-data + custom apps)

This folder is a **ready-to-import abapGit repository**. It now covers **two sets** of
RAP business objects in one bundle:

1. **13 master-data apps** (Fiori Elements / class-free managed BOs) — no ABAP behavior
   class needed; the pull activates without any hand-written ABAP.
2. **13 custom (freestyle) apps** (unmanaged RAP BOs *with* a behavior class that calls
   BAPIs) plus 2 background automation classes — these DO include their `zbp_i_*` /
   `zcl_*` ABAP behavior/automation classes.

Pulling it with abapGit creates the master-data objects (30 CDS views, 14 metadata
extensions, 26 behavior definitions, 13 service definitions) **and** the custom-app
objects (CDS interface/projection views, `ZD_*` abstract action entities, unmanaged
behavior definitions, `ZBP_I_*` behavior classes, 13 more service definitions) — instead
of hand-typing each one in ADT.

> **Activate the custom apps in small groups, not all at once.** The behavior classes
> carry drafted BAPI logic with `VERIFY`-tagged spots for release-specific field/status
> names; the first activation of each app is where any field/status mismatch vs your real
> tables surfaces. Pulling everything and activating in one batch means one bad object can
> cancel the whole activation batch — so activate app-by-app (or in small clusters) and we
> iterate on the errors. See `docs/CUSTOM_APPS_WIRING_PLAN.md` for the per-app BAPI map,
> complexity, and recommended order (start with Batch Status 🟢, end with the goods-movement
> group 🔴). The two automation classes (`ZCL_PO_AUTOMATION`, `ZCL_OBD_AUTOMATION`)
> reference config tables (`ZSOL_AUPO`, `ZMM_AUTOPO`, `ZSOL_HUDISPATCH`) that need
> verification against your system.

- Target package on KSD: **`ZKGPL_FIORI`**
- Branch: **`claude/fiori-apps-ui5-completeness-4bvlmp`**
- All objects bind **existing legacy Z-tables** — no new tables are created by the pull
  (except Shade, see prerequisites).
- The **master-data** behavior definitions are **class-free** (`managed;`, no
  `implementation in class`), so those activate without any hand-written ABAP. The
  **custom-app** behavior definitions are **unmanaged with `implementation in class`**, and
  their `ZBP_I_*` behavior classes are included in this bundle.

## What is / isn't included

| Included (imported by abapGit) | NOT included (do by hand — see below) |
|---|---|
| Interface CDS views `ZI_*` | Service **bindings** `ZUI_*_O4` (create via ADT wizard) |
| Projection CDS views `ZC_*` | The **Publish** step (blocked until Basis config — see below) |
| Metadata extensions `ZC_*` | Behavior **classes** (deliberately omitted — objects are class-free) |
| Behavior definitions (master-data class-free; custom-app unmanaged) | Table **`ZDD_SHADE`** (already built on KSD) |
| Service definitions `ZUI_*` (26 total) | |
| Behavior classes `ZBP_I_*` (custom apps) + `ZCL_*` automation | |
| Abstract action entities `ZD_*` (custom-app action params/results) | |

## Prerequisites (once)

1. **abapGit installed on KSD** — the `ZABAPGIT` standalone report, or the abapGit
   plug-in in ADT/Eclipse. (If not installed, ask Basis to import the standalone report.)
2. **Package `ZKGPL_FIORI`** exists (it does — Shade was built there).
3. **Table `ZDD_SHADE`** exists (it does — already built on KSD). Its DDL is in
   `backend/shade-master-rap/src/zdd_shade.table-spec.md` if a rebuild is ever needed.
   The other 12 apps bind pre-existing legacy tables (`zpp_receipe`, `zpp_jobn`,
   `zgp_hdr`/`zgp_item`, `ztb_truck_mstr`, …).

## Import steps

1. Run **`ZABAPGIT`** (or open abapGit in ADT).
2. **New Online Repository** →
   - URL: the `Fiori-Apps` Git URL
   - Branch: `claude/fiori-apps-ui5-completeness-4bvlmp`
   - Package: `ZKGPL_FIORI`
   abapGit reads `/.abapgit.xml` at the repo root, whose `STARTING_FOLDER` points here
   (`/backend/_abapgit_import/src/`), so only these 83 objects are in scope — the UI5
   apps, docs, etc. are ignored.
3. **Pull**. abapGit resolves dependency order and activates the objects (interface →
   projection → metadata extension → behavior). If a first pass leaves a few inactive,
   just **Pull / activate again** — CDS cross-references settle on the second pass.
4. For **each** service definition, create the **service binding** in ADT:
   right-click `ZUI_<app>` → *New Service Binding* → Binding Type **OData V4 - UI** →
   name `ZUI_<APP>_O4` → **Activate**.

## ⚠ The Publish gate (same blocker as Shade)

On this fresh Initial-Shipment KSD system, **OData V4 local publishing is not yet
enabled**. The binding **Publish** step fails with *"Local Publish failed"* until Basis
runs the task list **`SAP_GATEWAY_BASIC_CONFIG`** in transaction **STC01** (one-time,
system-wide). Do the abapGit pull and create the bindings now; **Publish all bindings in
one pass after Basis completes that task list.**

## Object inventory (13 apps → 83 objects)

Shade · Recipe · Schedule · Job · Merge · Packing-Material · Transport-Code · Truck ·
C-Form · Checked/Packed-By · Digital-Signature · Export-Detail · Gate-Pass (composition:
header + item + associated part).

> The full copy-paste build packs (for building any single app by hand in ADT without
> abapGit) are in `docs/` as the Master-Data Build Packs document.
