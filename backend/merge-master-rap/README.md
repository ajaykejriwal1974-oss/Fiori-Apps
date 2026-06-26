# Merge Details (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Merge Details" app is generated from the service binding via the
metadata extension `zc_merge.ddlx`.

> Likely a batch/lot merge log - VERIFY the exact purpose against ZMERGE.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_merge.ddls.asddls` | `ZI_Merge` | Interface CDS over `zmerge` |
| `zc_merge.ddls.asddls` | `ZC_Merge` | Projection (`transactional_query`) |
| `zi_merge.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_merge.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_merge.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_merge.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_merge.srvd.srvdsrv` | Service def `ZUI_MERGE` | exposes `ZC_Merge` |

## Create in ADT
- DB table `zmerge`: `merge_id` (key char10), `material` char40, `source_batch` char10, `target_batch` char10, `merge_date` dats, `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_MERGE_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
