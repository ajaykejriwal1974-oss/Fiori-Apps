# Transport Code Master (ZTRANS) — managed RAP over `ZTRANS`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZTRANS`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_transport.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table.
> **Value helps** (standard `I_*StdVH`; shade fields → the Shade master
> `ZC_DD_Shade`) and **in-table text** are wired on the projection/interface —
> VERIFY the released VH names per release before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `TransportCode` | `ZZTRCODE` | 🔑 |
| `TruckNumber` | `ZZTRCKNO` | 🔑 |
| `Description` | `ZZTRDESC` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_transport.ddls.asddls` | `ZI_Transport` | Interface CDS over `ztrans` |
| `zc_transport.ddls.asddls` | `ZC_Transport` | Projection (`transactional_query`) |
| `zi_transport.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_transport.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_transport.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_transport.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_transport.srvd.srvdsrv` | Service def `ZUI_TRANSPORT` | exposes `ZC_Transport` |

## Create in ADT
- The table `ZTRANS` **already exists** — the managed BO binds to it
  as `persistent table ztrans`. No DDIC table to create.
- Key: `ZZTRCODE`, `ZZTRCKNO`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_TRANSPORT_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
