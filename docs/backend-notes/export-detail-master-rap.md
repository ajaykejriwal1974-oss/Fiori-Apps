# Export Details Master (ZMBR2) — managed RAP over `ZEXP`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZEXP`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_export_detail.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `BillingDocument` | `VBELN` | 🔑 |
| `ConditionType` | `KSCHL` | 🔑 |
| `NetValue` | `NETWR` |  |
| `Currency` | `WAERK` |  |
| `ExchangeRate` | `KURSK` |  |
| `BillingDate` | `FKDAT` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_export_detail.ddls.asddls` | `ZI_ExportDetail` | Interface CDS over `zexp` |
| `zc_export_detail.ddls.asddls` | `ZC_ExportDetail` | Projection (`transactional_query`) |
| `zi_export_detail.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_export_detail.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_export_detail.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_export_detail.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_export_detail.srvd.srvdsrv` | Service def `ZUI_EXPORT_DETAIL` | exposes `ZC_ExportDetail` |

## Create in ADT
- The table `ZEXP` **already exists** — the managed BO binds to it
  as `persistent table zexp`. No DDIC table to create.
- Key: `VBELN`, `KSCHL`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_EXPORT_DETAIL_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
