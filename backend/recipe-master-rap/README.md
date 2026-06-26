# Dyeing Recipe Master (ZRECP01/02/03) — managed RAP over `ZPP_RECEIPE`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZPP_RECEIPE`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_recipe.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table. Wire
> value helps (reuse `ZSOL_F4*`) and confirm before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `Plant` | `WERKS` | 🔑 |
| `GreyCode` | `GREY_CODE` | 🔑 |
| `DyeCode` | `DYE_CODE` | 🔑 |
| `ShadeCode` | `SHDCD` | 🔑 |
| `ItemNumber` | `POSNR` | 🔑 |
| `GreyItemDesc` | `GREY_ITEM` |  |
| `DyeItemDesc` | `DYE_ITEM` |  |
| `Component` | `COMPONENT` |  |
| `ComponentDesc` | `COMP_DESC` |  |
| `ComponentType` | `COMP_TYPE` |  |
| `Ratio` | `RATIO` |  |
| `SalesUnit` | `VRKME` |  |
| `Remarks` | `REMARKS` |  |
| `CreatedBy` | `ERNAM` |  |
| `CreatedOnDate` | `ERDAT` |  |
| `CreatedAtTime` | `ERZET` |  |
| `LastChangedBy` | `LASTUSER` |  |
| `LastChangedDate` | `LASTDATE` |  |
| `LastChangedTime` | `LASTTIME` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_recipe.ddls.asddls` | `ZI_Recipe` | Interface CDS over `zpp_receipe` |
| `zc_recipe.ddls.asddls` | `ZC_Recipe` | Projection (`transactional_query`) |
| `zi_recipe.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_recipe.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_recipe.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_recipe.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_recipe.srvd.srvdsrv` | Service def `ZUI_RECIPE` | exposes `ZC_Recipe` |

## Create in ADT
- The table `ZPP_RECEIPE` **already exists** — the managed BO binds to it
  as `persistent table zpp_receipe`. No DDIC table to create.
- Key: `WERKS`, `GREY_CODE`, `DYE_CODE`, `SHDCD`, `POSNR`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_RECIPE_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
