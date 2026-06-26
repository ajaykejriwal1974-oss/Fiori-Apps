# Checked / Packed By (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Checked / Packed By" app is generated from the service binding via the
metadata extension `zc_checked-by.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_checked-by.ddls.asddls` | `ZI_CheckedBy` | Interface CDS over `zcheckedby` |
| `zc_checked-by.ddls.asddls` | `ZC_CheckedBy` | Projection (`transactional_query`) |
| `zi_checked-by.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_checked-by.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_checked-by.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_checked-by.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_checked-by.srvd.srvdsrv` | Service def `ZUI_CHECKEDBY` | exposes `ZC_CheckedBy` |

## Create in ADT
- DB table `zcheckedby`: `operator_id` (key char10), `operator_name` char40, `operator_role` char10 (Checker/Packer), `plant` char4, `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_CHECKEDBY_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
