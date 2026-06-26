# Export Details (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Export Details" app is generated from the service binding via the
metadata extension `zc_export-detail.ddlx`.

> Assess against standard Foreign Trade / SD export first; build only if no standard fit.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_export-detail.ddls.asddls` | `ZI_ExportDetail` | Interface CDS over `zexportdtl` |
| `zc_export-detail.ddls.asddls` | `ZC_ExportDetail` | Projection (`transactional_query`) |
| `zi_export-detail.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_export-detail.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_export-detail.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_export-detail.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_export-detail.srvd.srvdsrv` | Service def `ZUI_EXPORTDETAIL` | exposes `ZC_ExportDetail` |

## Create in ADT
- DB table `zexportdtl`: `export_id` (key char10), `customer` char10, `country` land1, `incoterms` char3, `currency` waers, `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_EXPORTDETAIL_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
