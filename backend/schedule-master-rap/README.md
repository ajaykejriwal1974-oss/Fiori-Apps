# Schedule Master (ZSCH01/02/03(N)) — managed RAP over `ZPP_SCHEDULEN`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZPP_SCHEDULEN`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_schedule.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `ScheduleNumber` | `SCHNO` | 🔑 |
| `FiscalYear` | `GJAHR` | 🔑 |
| `Plant` | `WERKS` |  |
| `CardNumber` | `KDNO` |  |
| `ScheduleDate` | `SCHDT` |  |
| `ScheduleTime` | `SCHTIME` |  |
| `SalesDocument` | `VBELN` |  |
| `SalesItem` | `POSNR` |  |
| `DyeingDate` | `DYEDT` |  |
| `Material` | `MATNR` |  |
| `MaterialDesc` | `MAKTX` |  |
| `ScheduleQty` | `SCH_QTY` |  |
| `SalesUnit` | `VRKME` |  |
| `ShadeCode` | `SHDCD` |  |
| `Remarks` | `REMARKS` |  |
| `CompleteFlag` | `COMPLETE` |  |
| `DeletionFlag` | `DELIND` |  |
| `CreatedBy` | `ERNAM` |  |
| `CreatedOnDate` | `ERDAT` |  |
| `CreatedAtTime` | `ERZET` |  |
| `LastChangedBy` | `LASTUSER` |  |
| `LastChangedDate` | `LASTDATE` |  |
| `LastChangedTime` | `LASTTIME` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_schedule.ddls.asddls` | `ZI_Schedule` | Interface CDS over `zpp_schedulen` |
| `zc_schedule.ddls.asddls` | `ZC_Schedule` | Projection (`transactional_query`) |
| `zi_schedule.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_schedule.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_schedule.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_schedule.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_schedule.srvd.srvdsrv` | Service def `ZUI_SCHEDULE` | exposes `ZC_Schedule` |

## Create in ADT
- The table `ZPP_SCHEDULEN` **already exists** — the managed BO binds to it
  as `persistent table zpp_schedulen`. No DDIC table to create.
- Key: `SCHNO`, `GJAHR`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_SCHEDULE_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
