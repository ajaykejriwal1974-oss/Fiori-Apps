# abapGit import — KGPL master-data RAP backend

This folder is a **ready-to-import abapGit repository** for the 13 master-data RAP
business objects. Pulling it with abapGit creates **83 objects in one shot** (30 CDS
views, 14 metadata extensions, 26 behavior definitions, 13 service definitions) —
instead of hand-typing each one in ADT.

- Target package on KSD: **`ZKGPL_FIORI`**
- Branch: **`claude/fiori-apps-ui5-completeness-4bvlmp`**
- All objects bind **existing legacy Z-tables** — no new tables are created by the pull
  (except Shade, see prerequisites).
- All behavior definitions are **class-free** (`managed;`, no `implementation in class`),
  so **no ABAP behavior class is needed** and the pull activates without any hand-written ABAP.

## What is / isn't included

| Included (imported by abapGit) | NOT included (do by hand — see below) |
|---|---|
| Interface CDS views `ZI_*` | Service **bindings** `ZUI_*_O4` (create via ADT wizard) |
| Projection CDS views `ZC_*` | The **Publish** step (blocked until Basis config — see below) |
| Metadata extensions `ZC_*` | Behavior **classes** (deliberately omitted — objects are class-free) |
| Behavior definitions `ZI_*` / `ZC_*` (class-free) | Table **`ZDD_SHADE`** (already built on KSD) |
| Service definitions `ZUI_*` | |

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
