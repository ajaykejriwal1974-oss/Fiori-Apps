# Knitting Roll QC (Mango Filament, company code 8000)

Scan Suite screen **Knitting Roll QC** (feature `KNITQC`) plus a hold check
inside the packing transaction ZPACK01. Plants 8001 / 8003 (order type KNT).
Transport **KSDK906920**, package **ZSOL_ISCAN**.

## What it does

1. **Physical QC** – the operator scans the ZSBAR label (`MK0013/5443` =
   knitting machine / running roll number), picks a grade (ZPP_GRADE, order
   type KNT: A 1ST, B PQ, C OL, E INDT, R REJ), ticks defect codes, adds a
   remark and, when a dye sample is cut, ticks **Sample to Dyeing QC**. That
   tick puts the roll on **hold** (status `S` sent).
2. **Dyeing QC lab** – confirms the sample arrived (`R` received) and, when
   the result comes back (normally 2 days), enters **Cleared** (`C`) or
   **Failed** (`F`). Works on the handheld and on a desktop browser (same
   URL).
3. **Packing hold** – ZPACK01 refuses a roll whose status is `S` or `R`
   ("under Dyeing QC since … (n days)"), refuses a `F` roll as 1ST quality
   and defaults its grade to B, and refuses a roll graded R (rejected) at
   Physical QC. A roll with no QC record only gets a warning for now (one
   line to change in `knit_qc_check` once every roll is scanned).
4. **Lists** – hold list, pending-dye worklist (with days pending / overdue),
   actual production list by date / order / machine, all scoped to the
   plants the signed-in user holds.

Nothing here posts stock. GR + handling unit are still created by ZPACK01
exactly as before; ZREPACK (downgrade) is deliberately not checked.

## Objects

| Object | Type | Purpose |
|---|---|---|
| `ZKNIT_ROLL_QC` | table | one row per roll: key WERKS/ARBPL/MRNO, label text, order, Physical QC (grade, defects, remark, user/time), Dyeing QC (status S/R/C/F, sent/received/result dates + users, remark) |
| `ZKNIT_QC_DEFECT` | table (customizing) | defect codes; WERKS blank = all plants |
| `ZCL_ZKNIT_ROLL_QC` | class | all rules: parse label, resolve order via ZROLL print log / ZSOLOPENORD, record PQC / DRECV / DRES, `CHECK_PACK`, lists |
| `ZCL_ZSOL_KNIT_QC_MPC` | class | OData model `ZSOL_KNIT_QC_SRV`: RollSet, HoldSet, PendingDyeSet, ProductionSet, DefectCodeSet, GradeSet |
| `ZCL_ZSOL_KNIT_QC_DPC` | class | OData provider: GET sets, POST RollSet (Action PQC / DRECV / DRES); session check via `ZCL_ZSOL_APP_AUTH` |
| `ZSOL_ORD_DETAILS_WORK_CENT` | include of `ZPP_PACK_MODULE_NEW` | ZPACK01 hook: FORM `knit_qc_check`, called from MODULE `validate_mrno` and at the end of FORM `get_order_details` |
| `ZSOL_KNIT_QC_SEED` | report | one-off seeding of standard defect codes |

## Setup, in this order

1. **Tables** (Eclipse ADT, package ZSOL_ISCAN, transport KSDK906920):
   New > ABAP Repository Object > Dictionary > Database Table, name
   `ZKNIT_ROLL_QC`, paste `zknit_roll_qc.tabl.asddls`, activate. Same for
   `ZKNIT_QC_DEFECT`. Technical settings default (APPL0, size 0) are fine.
2. **Activate** `ZCL_ZKNIT_ROLL_QC`, then `ZCL_ZSOL_KNIT_QC_DPC` (both
   sources are already in KSD as inactive versions; MPC is active).
3. **Register the service** (SAP GUI, same as ZSOL_SCAN_READ_SRV):
   - `/IWBEP/REG_MODEL`: model `ZSOL_KNIT_QC_MDL` v1, class
     `ZCL_ZSOL_KNIT_QC_MPC`, package ZSOL_ISCAN.
   - `/IWBEP/REG_SERVICE`: service `ZSOL_KNIT_QC_SRV` v1, class
     `ZCL_ZSOL_KNIT_QC_DPC`, assign model `ZSOL_KNIT_QC_MDL` v1.
   - `/IWFND/MAINT_SERVICE` > Add Service, alias LOCAL, `ZSOL_KNIT_QC_SRV`,
     package ZSOL_ISCAN. Check
     `/sap/opu/odata/sap/ZSOL_KNIT_QC_SRV/$metadata` answers.
4. **ZPACK01 hook**: activate include `ZSOL_ORD_DETAILS_WORK_CENT`
   (program ZPP_PACK_MODULE_NEW) from `zsol_ord_details_work_cent.abap`.
5. **Defect codes**: create and run report `ZSOL_KNIT_QC_SEED` (untick
   Test), or type them in SE16N. Generate a table maintenance dialog in
   SE11 if the QC team should maintain codes in SM30.
6. **Scan Suite**: feature `KNITQC` in the admin screen, granted to the
   Mango Filament QC users (company code 8000 / plants 8001, 8003). Deploy
   the app (`npm run deploy`).

## Service contract (used by index.html)

```
GET  RollSet?$filter=Zmrno eq 'MK0013/5443'            one roll, resolved
POST RollSet  {Zmrno, Action:'PQC',  PqcGrade, PqcDefects:'HOLE;NDLN', PqcRemark, DyeSample:'X'}
POST RollSet  {Zmrno, Action:'DRECV'}
POST RollSet  {Zmrno, Action:'DRES', DqcStatus:'C'|'F', DqcRemark}
GET  HoldSet                                            S / R / F rolls
GET  PendingDyeSet                                      S / R rolls, DaysPending
GET  ProductionSet?$filter=PqcDate ge '20260901' and PqcDate le '20260906'
                    [and Aufnr eq '1043647'] [and Arbpl eq 'MK0013']
GET  DefectCodeSet?$filter=Werks eq '8001'
GET  GradeSet
```
Every call carries `X-Scan-Token`; POST additionally needs feature KNITQC and
the roll's plant among the user's grants.

## Suggestions already built in

- The hold is enforced where the mistake happens (ZPACK01), not only shown on
  a list – the list is for chasing the lab, the check is what prevents the
  repack.
- Dyeing-QC hold is started by the Physical QC operator and confirmed by the
  lab on receipt, so a sample that never reached the lab is visible
  (status S with days pending climbing) instead of silently lost.
- A failed result does not block packing outright – it blocks **1ST quality**
  and defaults the grade down, which is what the repack used to do by hand.
- Results can be corrected (C→F or F→C); the previous verdict is kept in the
  remark.
