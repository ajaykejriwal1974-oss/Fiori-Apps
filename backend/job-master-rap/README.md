# Job Master (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as a **managed RAP** business object - same pattern as `backend/shade-master-rap`
(framework owns the custom table). The Fiori Elements "Manage Job Master" app is
generated from the service binding via the metadata extension `zc_job.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** (and confirm there is truly no standard app in
> the Fiori Apps Reference Library) before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_job.ddls.asddls` | `ZI_Job` | Interface CDS over `zjob` |
| `zc_job.ddls.asddls` | `ZC_Job` | Projection (`transactional_query`) |
| `zi_job.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_job.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_job.clas.abap` + `.locals_imp` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_job.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_job.srvd.srvdsrv` | Service def `ZUI_JOB` | exposes `ZC_Job` as `Job` |

## Create in ADT
- DB table `zjob` (spec below) + service binding `ZUI_JOB_O4` (OData V4 - UI).

### Table `zjob` (DDIC)
| `job_number` (key, char10), `job_name` char40, `job_type` char20, `plant` char4, `work_center` char8, `is_active` abap_boolean |
- Admin fields: `created_by abp_creation_user`, `created_at abp_creation_tstmpl`,
  `last_changed_by abp_lastchange_user`, `last_changed_at abp_lastchange_tstmpl`,
  `local_last_changed_at abp_locinst_lastchange_tstmpl`.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
