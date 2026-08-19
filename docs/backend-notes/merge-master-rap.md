# Merge Details Master (ZMERGE) — managed RAP over `ZPP_MERGE`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZPP_MERGE`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_merge.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `OrderNumber` | `AURNR` | 🔑 |
| `Grade` | `GRADE` | 🔑 |
| `EndUse` | `ENDUSE` | 🔑 |
| `Batch` | `CHARG` |  |
| `ShadeCode` | `SHDCD` |  |
| `Quantity` | `MENGE` |  |
| `ShadeCode2` | `SHDCD2` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_merge.ddls.asddls` | `ZI_Merge` | Interface CDS over `zpp_merge` |
| `zc_merge.ddls.asddls` | `ZC_Merge` | Projection (`transactional_query`) |
| `zi_merge.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_merge.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_merge.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_merge.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_merge.srvd.srvdsrv` | Service def `ZUI_MERGE` | exposes `ZC_Merge` |

## Create in ADT
- The table `ZPP_MERGE` **already exists** — the managed BO binds to it
  as `persistent table zpp_merge`. No DDIC table to create.
- Key: `AURNR`, `GRADE`, `ENDUSE`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_MERGE_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
