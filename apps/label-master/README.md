# Label Master

Maintain the dyeing label master. Clean-core replacement for **`ZLABEL`**
(program `SAPMZ_PP_LABEL_001`, *"Maintain Label Master"*).

Closes gap #3 from `docs/fiori-gap-analysis-2026-08-19.md`. It is item 3 in the
packing section of the scanned runbook — the packing desk still opens SAP GUI
for it, and there is no tile for it in any of the five FLP spaces.

## ⚠️ One thing to finish before activation

The field list of the legacy table **`ZPP_LABEL`** could not be read when this
was written (ADT was unreachable). Every `ZPP_LABEL` field name is confined to
**two places**:

1. the `SELECT` list of `backend/src/zi_label_master.ddls.asddls`
2. the `mapping for zpp_label` block of `backend/src/zi_label_master.bdef.asbdef`

Both carry a VERIFY banner. Open `SE11` → `ZPP_LABEL` → *Fields*, correct the
left-hand column in those two blocks, and the app is done. The aliases on the
right-hand side (`Plant`, `Brand`, `LabelNumber`, `LabelText`, …) are what the
projection, service and UI address, so **nothing else changes**.

If a field genuinely does not exist on `ZPP_LABEL` (say there is no `shade`),
delete that one line from both blocks and from `zc_label_master.ddls.asddls`.

## What the legacy screen looks like

```
Maintain Label Master
  Dyeing ( 2002 )                 <- plant
    ( ) Kejriwal
    ( ) Karishma                  <- brand
    ( ) Microtex
    (•) Blank
  [Execute]
```

So `Plant` + `Brand` are the leading keys, and `LabelNumber` is the line key
within a brand. The Fiori app turns the radio group into an ordinary filter —
the user can now see all four brands at once instead of one at a time.

## What it does

Fiori Elements **List Report + Object Page** over a managed RAP service, so it
gets create / edit / delete, draft-free direct edit, variant management,
personalisation, and Excel export with no custom code.

- Filter by company code, plant, brand, material, grade, shade, active flag.
- Free-text search across material and label text.
- Create, change and delete label lines.
- `LabelNumber` is assigned by RAP (`numbering : managed`) — the user never
  types it.
- `Plant`, `Brand` and `LabelText` are mandatory; the audit fields are read-only.

## Backend objects (`backend/src`, package `ZKGPL_FIORI`)

| Object | Type | Purpose |
| --- | --- | --- |
| `ZI_LABEL_MASTER` | DDLS | Root view over `ZPP_LABEL` + `T001K` **(VERIFY field names)** |
| `ZC_LABEL_MASTER` | DDLS | Projection, `provider contract transactional_query` |
| `ZI_VH_LABEL_BRAND` | DDLS | Brand value help — `select distinct brand from zpp_label` |
| `ZI_LABEL_MASTER` | BDEF | **Managed**, `persistent table zpp_label`, create/update/delete **(VERIFY mapping)** |
| `ZC_LABEL_MASTER` | BDEF | Projection |
| `ZBP_I_LABEL_MASTER` | CLAS | Behaviour pool (empty — RAP owns the persistence) |
| `ZUI_LABEL_MASTER` | SRVD | Service definition (+ 4 value-help entity sets) |
| `ZUI_LABEL_MASTER_04` | SRVB | OData V4 binding |

Service URI: `/sap/opu/odata4/sap/zui_label_master_04/srvd/sap/zui_label_master/0001/`

This is the first **managed** behaviour definition in the package — every other
app here is unmanaged because it wraps a BAPI. A label master has no BAPI
behind it; it is a small table the packing desk edits, which is exactly what
managed RAP is for.

## Deploy

1. Finish the VERIFY step above.
2. abapGit pull in `ZABAPGIT` on KSD, then activate in Eclipse (ADT).
3. Publish service binding `ZUI_LABEL_MASTER_04`.
4. `npm install && npm run deploy` — BSP application `ZLABEL_MASTER`.
5. Add the tile to the **Production → Master Data** section, next to
   *Packing Material Master* and *Shade Master*; semantic object `LabelMaster`,
   action `maintainKejriwal`.

## Authorisations

`ZI_LABEL_MASTER` declares `authorization master ( instance )`. Add the plant
check in the behaviour pool before this goes to production, so a plant-2002
operator cannot edit another plant's labels. Until then, restrict by role.
