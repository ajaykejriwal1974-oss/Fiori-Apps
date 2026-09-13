# Backend fixes — 30 Aug 2026

Five ABAP objects. The CDS half of the Job Master work is **already active in
KSD**; everything in this folder needs Eclipse, because behaviour pools,
function modules and function groups cannot be activated over the ADT REST API
the way DDLS and SRVD can.

Transport: **KSDK906759** (KSDK906760 is a task under it, not a second request).

## Already done, no action needed

| Object | What changed | State |
|---|---|---|
| `ZC_Job` | four value helps added — Batch, Schedule, both work centres | **active in KSD** |
| `Z_KGPL_BATCH_MAINTAIN` | mode `'R'` removed | **written, INACTIVE** |

`ZC_Job` was verified against the live service: all four F4 endpoints answer 200
with real rows. The schedule help points at `ZI_Schedule`, not `ZC_Schedule` —
the projection is a `transactional_query` and the F4 service raised
`UNCAUGHT_EXCEPTION` when it was used as a value-help entity. That was found by
calling the endpoint, not by reading the code.

`Z_KGPL_BATCH_MAINTAIN`'s new source is written and sits inactive: activating it
needs `SAPLZKGPL_HU` locked in a transport, which the REST activation could not
arrange. Open the function module in Eclipse and activate it — the source is
already what you want, and `z_kgpl_batch_maintain.abap` here is the same text if
you would rather paste it.

## To activate in Eclipse

### 1. `Z_KGPL_BATCH_MAINTAIN` — stop writing 'X' into a date

Mode `'R'` set `BAPIBATCHATT-AVAILABLE = abap_true`. `AVAILABLE` is data element
**VERAB, "Availability date"** — a DATS field, not a status flag. Checked before
touching it: no `MCHA` row in KSD carries a non-initial `VERAB`, so it had never
run; the UI had been failing on a parameter mismatch first. An unknown mode now
returns without calling the BAPI.

### 2. `ZBP_I_BATCH_STATUS` (locals_imp) — Close Batch refuses

Paired with the above. The action returns a message explaining why instead of
queuing mode `'R'`. Both apps already refuse client-side, so this is the
backstop. `deleteBatch` is untouched — mode `'D'` sets `DEL_FLAG` (LVORM), which
is the deletion indicator it looks like.

### 3. `ZBP_I_WIP_BATCH_MGMT` (locals_imp) — the seven close guards

`ZSOL_WIP_BATCH_CLOSE` refuses to close on seven conditions; the app closed on
the flag alone. `why_not_ready` ports all seven, reading the same tables the
report reads:

| Figure | Source |
|---|---|
| posted / unposted boxes | `ZPP_PACK-NETWT` split on `GRPOST`, `MERGNO` = batch, `MATNR` = dyed code |
| yarn and oil consumption | `MSEG-MENGE` on `AUFNR` + `WEMPF` = batch + `MJAHR`, signed by `SHKZG` |
| COGI | `AFFW-ERFMG` on `WEMPF` = batch |
| oil BOM quantity | batch quantity × `RESB-ESMNG` for the non-grey component |

One deliberate difference: the report hard-codes `WERKS = '2002'` in its `MSEG`
reads; this uses the batch's own plant.

It also writes `CLOSED_BY / CLOSED_ON / CLOSED_TIME` on close and
`REOPEN / REPDAT / REPUN / REPTM` on reopen. Those four reopen columns have been
on `ZPP_BATCHN` all along and nothing has ever written them — the legacy report
has no reopen at all.

**Still not stored: the reason.** `ZPP_BATCHN` has no column for it.
`ZD_WIP_BATCH_CLOSE` claims it is "stored with the change"; that comment is
wrong. Storing it needs a `REASON` column on `ZPP_BATCHN` or an SLG1 log —
decide which, and the handler is one line from doing it.

### 4. `ZI_Job` + `ZI_JOB` behaviour + `ZBP_I_JOB` — activate the three together

- `zi_job.ddls.asddls` — `where delind <> 'X'`
- `zi_job.bdef.asbdef` — `managed with additional save`, `delete` replaced by a
  `markDeleted` action, `DeletionFlag` read-only
- `zbp_i_job.clas.locals_imp.abap` — `stashOldBatch` determination, `markDeleted`,
  and a `save_modified` that maintains `ZPP_BATCHN-ASSIGNED`

**Activate all three in one go.** The filter and the read-only flag are a pair:
filtering alone, with `DeletionFlag` still editable, lets a user save a row that
then vanishes from under the managed runtime's re-read.

What this fixes:

- Creating a job card now stamps `ZPP_BATCHN-ASSIGNED = 'X'`, and moving a card
  to another batch releases the old one — the two statements `ZJOB01N` runs in
  `MZ_PP_JOB_CARDNF01`, which the app did not.
- Delete is soft, matching the transaction, instead of removing the row.
- 24 soft-deleted job cards stop appearing in the app.

Note for whoever reviews it: `ZJOB01N`'s own delete is broken —
`UPDATE zpp_batchn SET assigned = space WHERE batchno = wa_tab-jobno` compares a
batch number against a job number, so the flag almost never clears. **15 batches
in KSD are flagged `ASSIGNED = 'X'` with no job card against them.** Fourteen are
2012-era `K####/13` rows with no order, no quantity and no author — migration
residue rather than fallout from the bug. The one that looks real is
`1810008131` (2015, order 000001001781, created by KID_PP).

## After activating

The two service definitions do not change, so no republish is needed. Redeploy
the three UI apps whose controllers changed:

```
cd ~/Desktop/Fiori-Apps
bash deploy-qc.sh        # unrelated — QC apps only
```

Batch Status, Batch Status FE and Contract Batch Update are not in that script
and are still on `package: "$TMP"`, so they cannot be transported at all yet.
Moving them to `ZKGPL_FIORI` on `KSDK906759` is the remaining piece.
