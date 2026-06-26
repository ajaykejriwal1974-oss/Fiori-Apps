# Schedule Master (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Schedule Master" app is generated from the service binding via the
metadata extension `zc_schedule.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_schedule.ddls.asddls` | `ZI_Schedule` | Interface CDS over `zschedule` |
| `zc_schedule.ddls.asddls` | `ZC_Schedule` | Projection (`transactional_query`) |
| `zi_schedule.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_schedule.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_schedule.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_schedule.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_schedule.srvd.srvdsrv` | Service def `ZUI_SCHEDULE` | exposes `ZC_Schedule` |

## Create in ADT
- DB table `zschedule`: `schedule_id` (key char10), `schedule_date` dats, `material` char40, `quantity` quan(13,3), `plant` char4, `schedule_status` char10, `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_SCHEDULE_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
