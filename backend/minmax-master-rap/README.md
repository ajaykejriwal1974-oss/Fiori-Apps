# Min-Max Levels (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Min-Max Levels" app is generated from the service binding via the
metadata extension `zc_minmax.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_minmax.ddls.asddls` | `ZI_MinMax` | Interface CDS over `zminmax` |
| `zc_minmax.ddls.asddls` | `ZC_MinMax` | Projection (`transactional_query`) |
| `zi_minmax.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_minmax.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_minmax.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_minmax.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_minmax.srvd.srvdsrv` | Service def `ZUI_MINMAX` | exposes `ZC_MinMax` |

## Create in ADT
- DB table `zminmax`: composite key `material` char40 + `plant` char4; `min_qty` quan(13,3), `max_qty` quan(13,3), `base_unit` unit(3), `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_MINMAX_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
