# Checked / Packed By Master (ZPCBY) — managed RAP over `ZPP_PCBY`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZPP_PCBY`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_checked_by.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `SerialNumber` | `SR_NO` | 🔑 |
| `CheckedPackedFlag` | `PC` | 🔑 |
| `UserName` | `USR_NAME` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_checked_by.ddls.asddls` | `ZI_CheckedBy` | Interface CDS over `zpp_pcby` |
| `zc_checked_by.ddls.asddls` | `ZC_CheckedBy` | Projection (`transactional_query`) |
| `zi_checked_by.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_checked_by.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_checked_by.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_checked_by.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_checked_by.srvd.srvdsrv` | Service def `ZUI_CHECKED_BY` | exposes `ZC_CheckedBy` |

## Create in ADT
- The table `ZPP_PCBY` **already exists** — the managed BO binds to it
  as `persistent table zpp_pcby`. No DDIC table to create.
- Key: `SR_NO`, `PC`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_CHECKED_BY_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
