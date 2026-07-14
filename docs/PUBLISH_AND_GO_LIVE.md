# Publish & Go-Live — KGPL master-data Fiori backends (KSD)

Status as of the abapGit import: **10 master-data apps + Shade fully built and active**
on KSD in package `ZKGPL_FIORI` — CDS views, metadata extensions, class-free managed
behavior definitions, service definitions, and OData V4 - UI service bindings.

Everything is built and activated. The **only** remaining step to make the apps live is
publishing the OData endpoints, which is gated by one one-time Basis task.

## 1. Basis: enable OData V4 local publishing (one-time, system-wide)

The bindings currently show **Local Service Endpoint: Unpublished**. On this fresh
Initial-Shipment system the OData V4 local-publishing infrastructure isn't configured yet,
so **Publish** fails with *"Local Publish failed"*.

**Action (Basis):** run task list **`SAP_GATEWAY_BASIC_CONFIG`** via transaction **`STC01`**.
This is a standard one-time activity that configures the local OData grouping/publishing
infrastructure. (Reference: SAP Gateway basic configuration.)

## 2. Publish all 11 bindings

After step 1, in ADT open each service binding and click **Publish** (or re-publish),
until each shows **Published**:

| # | Service Binding | Service Definition |
|---|-----------------|--------------------|
| 1  | `ZUI_DD_SHADE_04`            | `ZUI_DD_SHADE`            |
| 2  | `ZUI_RECIPE_O4`             | `ZUI_RECIPE`             |
| 3  | `ZUI_SCHEDULE_O4`          | `ZUI_SCHEDULE`           |
| 4  | `ZUI_JOB_O4`               | `ZUI_JOB`                |
| 5  | `ZUI_MERGE_O4`             | `ZUI_MERGE`              |
| 6  | `ZUI_PACKING_MATERIAL_O4`  | `ZUI_PACKING_MATERIAL`   |
| 7  | `ZUI_TRUCK_O4`             | `ZUI_TRUCK`              |
| 8  | `ZUI_CFORM_O4`             | `ZUI_CFORM`              |
| 9  | `ZUI_CHECKED_BY_O4`        | `ZUI_CHECKED_BY`         |
| 10 | `ZUI_DIGITAL_SIGNATURE_O4` | `ZUI_DIGITAL_SIGNATURE`  |
| 11 | `ZUI_EXPORT_DETAIL_04`     | `ZUI_EXPORT_DETAIL`      |
| 12 | `ZUI_TRANSPORT_O4`         | `ZUI_TRANSPORT`          |
| 13 | `ZUI_GTPASS_O4`           | `ZUI_GTPASS`             |

Once published, each app previews from the binding ("Preview" / the service URL) and can be
added to the Fiori Launchpad.

## 3. Make GitHub SSL trust permanent (for future pulls)

The abapGit online pull needed GitHub's certificate chain in **STRUST → SSL Client (Standard)**.
The trust dropped after an ICM restart during setup. **Basis:** import the GitHub cert chain
into `SSL Client (Standard)`, **Save**, restart ICM, and confirm it persists across restarts —
so future abapGit pulls (and the Gate Pass / Transport re-add below) work without re-fixing.

## Gate Pass + Transport — imported (all 13 apps now live)

Both are now active on KSD:

- **Transport** — managed BO on base table **`ZTRCKMSTR`** (keys `ZZTRCODE` / `ZZTRCKNO`);
  the `ZTRANS` view was not usable as a managed-BO persistence table. Description (`ZTRPTMSTR`)
  omitted; add via a read-only association if needed.
- **Gate Pass** — re-modelled as **two flat independent managed BOs** (header + item, no
  composition), and **renamed `GATEPASS` → `GTPASS`** (`ZI_GTPASS` / `ZC_GTPASS` /
  `ZI_GTPASS_ITEM` / `ZC_GTPASS_ITEM` / `ZUI_GTPASS`). The composition kept producing a
  corrupted runtime object that could neither activate nor be deleted; fresh names sidestep it.
  Create bindings `ZUI_GTPASS_O4` (header service).

### Cleanup — old corrupt Gate Pass objects
The original `ZC_GATEPASS` / `ZI_GATEPASS` / `ZC_GATEPASS_ITEM` / `ZI_GATEPASS_PART` etc. remain
on KSD as inactive, corrupted objects (they blocked both activation and deletion). They are
harmless and unused. To remove them, Basis can clear the inconsistent runtime via **SE14**
(Database Utility) → object → Activate and adjust database / Delete, then delete the ABAP objects.

## What was done (summary)

- abapGit standalone installed on KSD; GitHub SSL trust established (STRUST).
- Pulled 10 master-data apps + Shade from `backend/_abapgit_import/` into `ZKGPL_FIORI`.
- Fixes applied during activation: entity/DDL-source name alignment; cast CURR/QUAN and
  EXCRT-conversion-exit fields to plain decimals; class-free managed behavior definitions.
- All CDS, behaviors, service definitions, and 11 OData V4 - UI bindings **activated**.
