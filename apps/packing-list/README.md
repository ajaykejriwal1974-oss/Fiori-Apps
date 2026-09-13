# Packing List (`kejriwal.sd.packinglist`)

Assign, change and remove the packing-list number (`ZPP_PACK-PKLST`) on packed
boxes. Clean-core replacement for `ZSD_PACKING_LIST_*` — one app folds the
`ZPLIST01/02/03` (+`A`/`T`/`N`/`D`) and `ZPACKLIST*` plant/format variants.

| | |
|---|---|
| BSP | `ZPACKING_LIST` |
| Package | `ZKGPL_FIORI` |
| Service | `ZUI_PACKING_LIST` → `/sap/opu/odata4/sap/zui_packing_list_04/...` |
| Intent | `PackingList-manageKejriwal` |
| CDS | `ZI_PACKING_LIST` → `ZC_PACKING_LIST` (over `ZPP_PACK`) |

## Source recovery, 31.08.2026

This app was live in KSD **and** KSQ with no source in any local repository.
The files here were recovered from the deployed BSP on KSD
(`/sap/bc/ui5_ui5/sap/zpacking_list/`), whose `-dbg` build output is the
unminified original. If an earlier copy turns up elsewhere, diff before
assuming this one is behind.

## Changes made at recovery

**Columns.** The list showed nine fields. The plant 2002 dispatch desk selects
on more than that in `ZPACKLISTN` / `ZPRP`, so the CDS and the table gained
`MergeNumber` (the batch — `ZPP_PACK-MERGNO` is typed `CHARG_D`),
`ProductionOrder`, `StorageLocation`, `EndUse`, `PackingSize`, `LocalExport`,
`GrossWeight`, `PackingDate` and `CreatedBy`.

**A filter bar.** The table previously bound `/PackingList` with no filters and
no suspension — opening the app pulled an entity set holding 1,081,436 rows at
plant 2002 alone. It now uses the same pattern as Cancel Production
Confirmation: filters, a suspended binding, and Go in the title bar.

**Value helps.** `ZUI_PACKING_LIST` exposed only the main entity. It now also
exposes `PlantVH`, `BatchVH` (`ZI_VH_Batch`, the same WIP-batch list the Job
Card Report uses) and `ProductVH`.

**Shade.** Added after measuring, not before. Shade is not on `ZPP_PACK` — it
belongs to the schedule, so it is reached from the box's batch:

```
MERGNO -> ZPP_JOBN.BATCHNO -> ZPP_SCHEDULEN (SCHNO + GJAHR) -> ZPP_SHADE.SHDCD
```

`ZI_JobCardReport` resolves the same chain but also joins two aggregating
confirmation views to build its dyeing and winding dates; this view takes the
four tables directly instead of paying for that aggregation. `bat.gjahr <> '0000'`
is required — the 2012 migration left 192 duplicate `ZPP_BATCHN` rows under that
year, and without the guard they double rows.

Measured in KSD before adding: joining every box in the table returned
4,263,565 rows for 4,263,565 boxes (no fan-out), and `ZPP_JOBN` holds 131,316
job cards across exactly 131,316 distinct batches, so `BATCHNO` is unique and the
join cannot multiply rows. 1,044,654 of plant 2002's 1,081,436 boxes resolve a
shade (96.6%).

**Ship-to.** Header partner, `VBPA` `POSNR '000000'` `PARVW 'WE'`, name from
`KNA1`. The partner function was settled by evidence rather than opinion: this
join returns the same names the legacy ZPACKLISTN screen prints — e.g.
`PRASANNA TEXTILE MILLS INDIA PVT LT` on sales order 5118057977. Item-level
partners were not used; the header partner already reproduces the legacy output,
and a second join for the item override would double the cost for rows that do
not differ. 1,069,373 of plant 2002's 1,081,436 boxes resolve one (98.9%), which
matches the 1,069,394 that carry a sales order at all.

## Join cost

Six joins hang off the box table. None multiplies rows — measured in KSD,
31.08.2026, boxes in vs rows out:

| Join | Boxes | Rows |
|---|---|---|
| batch → job card (whole table) | 4,263,565 | 4,263,565 |
| sales order → ship-to (plant 2002) | 1,081,436 | 1,081,436 |

`ZPP_JOBN` holds 131,316 job cards across exactly 131,316 distinct batches, so
`BATCHNO` is unique and cannot fan out.

These measurements are KSD, which holds 4.26M boxes; **KSQ holds 27.3M**. Every
join is on an indexed key and the list binding is suspended until Go, so the read
is always a filtered subset. If this view is ever consumed unfiltered, re-measure
first.
