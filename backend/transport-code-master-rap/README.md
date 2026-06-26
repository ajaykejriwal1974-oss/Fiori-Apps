# Transport Code (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as **managed RAP** - same pattern as `backend/shade-master-rap`. The Fiori
Elements "Manage Transport Code" app is generated from the service binding via the
metadata extension `zc_transport-code.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** and confirm there is no standard app in the
> Fiori Apps Reference Library before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_transport-code.ddls.asddls` | `ZI_TransportCode` | Interface CDS over `ztranscode` |
| `zc_transport-code.ddls.asddls` | `ZC_TransportCode` | Projection (`transactional_query`) |
| `zi_transport-code.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_transport-code.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_transport-code.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_transport-code.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_transport-code.srvd.srvdsrv` | Service def `ZUI_TRANSPORTCODE` | exposes `ZC_TransportCode` |

## Create in ADT
- DB table `ztranscode`: `transport_code` (key char10), `transport_name` char40, `transport_mode` char10 (Road/Rail/Air), `is_active` abap_boolean
- Admin fields: `abp_creation_user/tstmpl`, `abp_lastchange_user/tstmpl`, `abp_locinst_lastchange_tstmpl`.
- Service binding `ZUI_TRANSPORTCODE_O4` (OData V4 - UI).

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
