# Truck Master (Route 7 custom master) - managed RAP

Custom master with **no standard SAP equivalent** (KEJRIWAL Z-portfolio, Route 7).
Built as a **managed RAP** business object - same pattern as `backend/shade-master-rap`
(framework owns the custom table). The Fiori Elements "Manage Truck Master" app is
generated from the service binding via the metadata extension `zc_truck.ddlx`.

> **Skeleton.** The field list is a best-effort starting point - **VERIFY it
> against the original Z program** (and confirm there is truly no standard app in
> the Fiori Apps Reference Library) before building.

## Objects in `src/`
| File | Object | Role |
|---|---|---|
| `zi_truck.ddls.asddls` | `ZI_Truck` | Interface CDS over `ztruck` |
| `zc_truck.ddls.asddls` | `ZC_Truck` | Projection (`transactional_query`) |
| `zi_truck.bdef.asbdef` | Behavior (managed) | create/update/delete, ETag, mapping |
| `zc_truck.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_truck.clas.abap` + `.locals_imp` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_truck.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_truck.srvd.srvdsrv` | Service def `ZUI_TRUCK` | exposes `ZC_Truck` as `Truck` |

## Create in ADT
- DB table `ztruck` (spec below) + service binding `ZUI_TRUCK_O4` (OData V4 - UI).

### Table `ztruck` (DDIC)
| `truck_number` (key, char20), `transporter_name` char40, `transport_code` char10, `driver_name` char40, `capacity_kg` dec(13,3), `is_active` abap_boolean |
- Admin fields: `created_by abp_creation_user`, `created_at abp_creation_tstmpl`,
  `last_changed_by abp_lastchange_user`, `last_changed_at abp_lastchange_tstmpl`,
  `local_last_changed_at abp_locinst_lastchange_tstmpl`.

## Branch
Developed on `claude/fiori-app-extensions-h1nb64`.
