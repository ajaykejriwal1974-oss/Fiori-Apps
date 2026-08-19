# Truck Master (ZTRUCK) — managed RAP over `ZTB_TRUCK_MSTR`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZTB_TRUCK_MSTR`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_truck.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `TruckNumber` | `TRUCKNO` | 🔑 |
| `CarrierName` | `CARRIER_NAME` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_truck.ddls.asddls` | `ZI_Truck` | Interface CDS over `ztb_truck_mstr` |
| `zc_truck.ddls.asddls` | `ZC_Truck` | Projection (`transactional_query`) |
| `zi_truck.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_truck.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_truck.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_truck.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_truck.srvd.srvdsrv` | Service def `ZUI_TRUCK` | exposes `ZC_Truck` |

## Create in ADT
- The table `ZTB_TRUCK_MSTR` **already exists** — the managed BO binds to it
  as `persistent table ztb_truck_mstr`. No DDIC table to create.
- Key: `TRUCKNO`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_TRUCK_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
