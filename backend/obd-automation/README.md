# Outbound-Delivery Automation (ZSDOBD/N → 1) — ABAP automation class

Clean-core successor to `ZSDOBD` / `ZSDOBDN` (`ZSD_OBD_AUTOMATION(_NEW)`). A
single class **`ZCL_OBD_AUTOMATION`** with **plant as a parameter**.

## What it does
1. Reads dispatch-ready handling units from **`ZSOL_HUDISPATCH`** (status =
   ready), grouped by sales order.
2. Creates one outbound delivery per sales order via the **Outbound Delivery
   API** (`BAPI_OUTB_DELIVERY_CREATE_SLS`) — `TODO`.
3. Posts goods issue (`BAPI_OUTB_DELIVERY_CONFIRM_DEC`) — `TODO`.
4. Updates the dispatch status on `ZSOL_HUDISPATCH`.

Reuses the dispatch table already modelled by
[`backend/dispatch-correction-rap`](../dispatch-correction-rap).

## Clean-core shape
- **An ABAP class, not a report.** Schedulable via **Application Job Scheduling**
  (`if_apj_*_exec_object`); runnable in ADT (F9) via `if_oo_adt_classrun`.
- `iv_test = abap_true` simulates (logs only).

## Wiring (TODO)
- The delivery-create + goods-issue API calls and the `ZSOL_HUDISPATCH` status
  update (see `run`). Confirm the "ready" status code (`c_status_ready`) against
  the legacy flow.
- The Application Job parameter definition for `WERKS`.

## Create in ADT
- Activate the class; register an **Application Job catalog entry** to schedule it
  with `WERKS` as a parameter.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`. See
[`docs/UPL-MIGRATION.md`](../../docs/UPL-MIGRATION.md) §D.
