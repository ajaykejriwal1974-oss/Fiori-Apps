# Job Master (ZJOB01/02/03(N)) — managed RAP over `ZPP_JOBN`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZPP_JOBN`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_job.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `JobNumber` | `JOBNO` | 🔑 |
| `BatchNumber` | `BATCHNO` |  |
| `ScheduleNumber` | `SCHNO` |  |
| `Plant` | `WERKS` |  |
| `DyeingWorkCenter` | `DYE_ARBPL` |  |
| `WindingWorkCenter` | `WIN_ARBPL` |  |
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
| `zi_job.ddls.asddls` | `ZI_Job` | Interface CDS over `zpp_jobn` |
| `zc_job.ddls.asddls` | `ZC_Job` | Projection (`transactional_query`) |
| `zi_job.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_job.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_job.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_job.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_job.srvd.srvdsrv` | Service def `ZUI_JOB` | exposes `ZC_Job` |

## Create in ADT
- The table `ZPP_JOBN` **already exists** — the managed BO binds to it
  as `persistent table zpp_jobn`. No DDIC table to create.
- Key: `JOBNO`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_JOB_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
