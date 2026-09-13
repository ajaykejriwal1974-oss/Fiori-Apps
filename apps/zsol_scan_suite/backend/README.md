# Scan Suite backend — Create Challan rework (KSDK906917), Packing List box check (KSDK906920), batch log / report fix (KSDK906923) and Security-before-Challan (KSDK906943)

Package `ZSOL_ISCAN` on KSD. These are copies of the active sources as of
7 Sep 2026; the system of record is KSD, not this folder.

| Object | Status | What changed |
|---|---|---|
| `ZCL_ZSOL_OBD_CREATE` | new; **KSDK906943:** confirmed cartons only | Creates the real Challan for one packing list: VL01N by batch input (same key sequence as ZSDOBDN / `ZSD_OBD_AUTOMATION_NEW`), HUs packed, goods issue posted, LIKP `ZZTRCODE`/`ZZTRCKNO`, 621 for pallets/trolleys via `BAPI_GOODSMVT_CREATE`, then `ZSOL_CHALLAN_LOG` rows through `ZCL_ZSOL_CHALLAN_PACK=>PACK_BOXES`. Multi-batch orders (`ZVBAP_BATCH`) get one delivery per merge number with `LIPS-CHARG`. Returns a result structure; never raises. **Since 07.09.2026** (`IV_LOADED_ONLY`, default true) only cartons Security has confirmed go on the delivery; the rest come back with type `W` ("left on the packing list") and a list with no confirmed carton posts nothing. |
| `ZCL_ZSOL_CHALLAN_PACK__MPC_EXT` | rewritten; **KSDK906943:** `Mode`, `LoadedCount`, `Loaded` | Adds entity sets `PackingListSet`, `PackingListBoxSet` (filter required), `TruckSet` to service `ZSOL_CHALLAN_PACK_SRV_SRV` without touching the SEGW-generated classes. **07.09.2026:** `PackingList` gained the filterable `Mode` and `LoadedCount` (confirmed cartons); `PackingListBox` gained `Loaded` (`X`), `LoadDate`, `LoadTime`. `GET_LAST_MODIFIED` = 20260907 so the Gateway metadata cache rebuilds on import. |
| `ZCL_ZSOL_CHALLAN_PACK__DPC_EXT` | rewritten; **KSDK906943:** `Mode` | Serves the three new sets in a redefinition of `/IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_ENTITYSET`; `ChallanPackSet` POST with `App = 'D'` runs `ZCL_ZSOL_OBD_CREATE`. **07.09.2026:** `PackingListSet` honours `Mode eq 'LOAD'` (lists with cartons still to confirm — the Security Loading dropdown) and `Mode eq 'CHALLAN'` (lists with at least one confirmed carton — the Create Challan dropdown); every list row carries `LoadedCount`, every box row `Loaded`. The `ChallanPackSet` GET (pending deliveries, 0050 included) is kept for the Android scanner only. |
| `ZCL_ZSOL_SCAN_READ_MPC` / `_DPC` | changed | Fifth entity set `ZSOL_RESERVATION` on `ZSOL_SCAN_READ_SRV`: open manual reservation items (RESB/RKPF, BDART MR, not deleted/final, open qty > 0, movement allowed), scoped to the caller's plants on either side, newest first, capped at 300 — feeds the HU Movement reservation dropdown. **KSDK906920:** sixth and seventh sets `ZSOL_SO_BOXCHECK` (read) and `ZSOL_SO_BATCH` (read, POST, DELETE) — see below. |
| `ZCL_ZSOL_SO_BOXCHECK` | new (KSDK906920, v4 in KSDK906923, **v5 on KSDK906946**) | The rules of `ZRPT_SALES_SCAN` applied to one sales order's packed stock, item by item, with the verdict of every rule counted instead of only the survivors. Evaluates every `ZPP_PACK` row of a box (a box can carry several merge numbers / sizes). Also the two `ZVBAP_BATCH` writes (`ASSIGN_BATCH`, `REMOVE_BATCH`), each writing one `ZSOL_SOBATCH_LOG` row. **v5 (07.09.2026):** on an item that carries a single batch in `VBAP-CHARG`, `ASSIGN_BATCH` *replaces* that batch through `BAPI_SALESORDER_CHANGE` (logged `C`, old batch in NOTE) and `REMOVE_BATCH` clears it (logged `R`) — v4 refused both and sent the operator to VA02, which in plant 2002 was every item of every order. The list path is unchanged. v5 active on KSD 07.09.2026 evening, transport **KSDK906946** (KSDK906943 had been released). |
| `ZCL_PICKUPLOAD_DPC_EXT` | changed (KSDK906946) | SOLSYNCH's upload DPC, already extended with the session and plant checks. **07.09.2026:** before the `SUBMIT zrpt_sales_upload` it exports `sochg` = 'X' to ABAP memory `ZSOL_SOCHG` when the signed-in user holds the SOCHG screen (never for a service user), and frees it after. Read by the include below. |
| `ZRPT_SALES_UPLOAD_FR` | changed (KSDK906946) | Include of SOLSYNCH's `ZRPT_SALES_UPLOAD`, `FORM post_box`: (1) for a piece unit on the order item (ROL/PC/PCE/ST/EA) every box counts one instead of its weight — the roll-count rule the Packing List applies since KSDK906943; (2) with the `ZSOL_SOCHG` flag the upper tolerance is the larger of ZSDTOL and 10% of KWMENG (10% of ZMENG on the contract branch, which sales org 2002 already had). **Saved as the INACTIVE version by the bridge** (`REPOSRC` R3STATE I, 07.09 20:59) — open the include in Eclipse and activate (Ctrl+F3); it will ask for a request: KSDK906946. `zrpt_sales_upload_fr.abap` here is that version. |
| `ZSOL_SOBATCH_LOG` | new table (KSDK906923) | Audit log of batches named on / taken off an order from the Scan Suite: `LOGID` (UUID), `VBELN`, `POSNR`, `CHARG`, `ACTION` (A assign / R remove), `APP_USER` (Scan Suite login), `SAP_USER`, `LOG_DATE`, `LOG_TIME`, `SOURCE` (`SCAN`), `NOTE` (material and plant). DDL in `zsol_sobatch_log.tabl.asddls`; read it with SE16N. |
| `ZRPT_SALES_SCAN_FR` | changed (KSDK906923) | Include of `ZRPT_SALES_SCAN`. `FORM get_data` now reads `ZVBAP_BATCH` **per item** (`READ TABLE gt_sfinal WITH KEY vbeln posnr`) and keeps `VBAP-CHARG` for the items that have no batch list, instead of pinning every batch of the order to the first item. `zrpt_sales_scan_fr.abap` here is the active include (the bridge saves an include only as inactive — activate it in Eclipse with Ctrl+F3). |
| `ZCL_ZSOL_PROD_JOBCARD` | changed (KSDK906946) | Dyeing batches and job cards through the RAP objects (KSDK906927, released). **07.09.2026:** `LIST_SCHEDULES` with `IV_OPEN_ONLY` drops schedules that are already fully or over-batched (batched ≥ scheduled) — on plant 2002 they filled the top of the list; a schedule asked for by number (`IV_SCHNO`) comes back whatever its state, so a typed or scanned number still works. Mirror in `zcl_zsol_prod_jobcard.abap`. |
| `ZCL_ZSOL_CHALLAN_PACK` | changed | `PACK_BOXES` gained optional `IV_DELIV_NUMB`, so the caller that created the delivery can name it instead of the LIPS guess. (Not copied here — one parameter and one `IF`.) |

## Why the Packing List shows "0 box(es)" for some plants / orders

The Packing List's box list comes from `ZRPT_SALES_SCAN` (via
`ZSOL_PICK_DOWNLOAD_SRV`). A packed handling unit is offered for an order
item only when **all** of these hold:

1. same material, plant **and storage location** as the order item (VEPO
   vs VBAP-LGORT — 2002 stock in DFGT is invisible to an item that says
   DFG1);
2. HU batch = a batch the order names — `ZVBAP_BATCH` rows for the order
   (VA01/VA02 custom batch tab), else `VBAP-CHARG`. **A blank order batch
   matches only a blank HU batch.** Make-to-stock plants (2002, Mango
   8001/8003) pack every box under a batch, so an order that names none
   gets nothing;
3. ZPP_PACK size within the order's `ZZSIZE/ZZSIZ1/ZZSIZ2` set and grade
   within `ZZGRADE/ZZGRAD1/ZZGRAD2`;
4. box not already stamped with a sales order (`ZPP_PACK-VBELN` blank)
   and not on a delivery (VEKP `VPOBJ` 01);
5. packing record posted (`HUPOST` or `REPACK` set, `DELIND` blank).

Rule 2 is what produced the two production examples (SO 5126072459 in
plant 2002, SO 5126072528 at Mango). `ZSOL_SO_BOXCHECK` reports, per
item, how many boxes failed which rule and which batches would pass
everything else; the Packing List shows it automatically when an order
loads with 0 boxes ("Why no boxes?" card) and a user holding the **SOCHG**
grant can name one of those batches on the item from the same card.

Fixed divergence (KSDK906923): `ZRPT_SALES_SCAN` used to read
`ZVBAP_BATCH` per **order** and take the first item's material for every
batch (`READ TABLE gt_sfinal WITH KEY vbeln`), so on a multi-material
order a batch named on a later item made the whole order return 0 boxes
while the check said "n HU(s) can be picked". `ZRPT_SALES_SCAN_FR` now
matches each batch to its own item and keeps `VBAP-CHARG` for the items
without a batch list. Verified on KSD 06.09.2026 with SO 5125000048
(plant 1000, five materials): item 30 with no batch → 165 boxes; batch
FC62000134 named on item 30 from the card → 174 lines (8 cartons + the
pallet line of the carton on pallet 9100000090), the other four items
unchanged.

One rule the card has to respect, from `MV45AFZZ` ("Single Batch And
Multiple Batches are not Allowed at Single line item"): an item carries
**either** `VBAP-CHARG` **or** `ZVBAP_BATCH` rows. The card therefore
offers tap-to-assign only on items whose `batch_src` is not `C`; for a
`C` item it tells the operator to change the batch on the item in VA02.
The class refuses the write as well ("Item 20 already carries batch
FD36010031 as its single batch - change it on the order item (VA02)
instead", verified on KSD 06.09.2026).

Every assign / remove from the card is logged in `ZSOL_SOBATCH_LOG` with
the Scan Suite login, so a batch that appears on an order can be traced
back to who named it and when.

## Service contract used by `apps/zsol_scan_suite/index.html`

```
GET  PackingListSet                              all packing lists with cartons still to challan, caller's plants
GET  PackingListSet?$filter=Mode eq 'LOAD'       ... with cartons Security has still to confirm  (Security Loading Scan)
GET  PackingListSet?$filter=Mode eq 'CHALLAN'    ... with at least one confirmed carton           (Create Challan)
GET  PackingListSet?$filter=So eq '5825000003' and Mode eq '…'   one order (server checks the order grant)
     rows: So, SoItem, Pklst, PlDate, BoxCount, LoadedCount, NetWt, Plant, Material, MatDesc, Customer, CustName, Mode
GET  PackingListBoxSet?$filter=So eq '…' and SoItem eq '…' and Pklst eq '…'
     rows: Boxno, So, SoItem, Pklst, Exidv, Ptype, PtypeText, NetWt, Mergno, HuStatus, Loaded ('X'), LoadDate, LoadTime
GET  TruckSet
POST ChallanPackSet  { App: 'D', BoxData: 'So|SoItem|Pklst|YYYYMMDD|Trcode|Trckno' }
     ->  BoxData    = 'R|type|message;' + 'D|delivery|type|message;'*
         SoItemList = 'B|boxno|type|message;'* + 'L|log line;'*      type W = not confirmed by Security, left on the list
```

### Security confirms before the Challan (07.09.2026, KSDK906943)

The order of the last two screens was inverted by the process owner:
**Packing List → Security Loading Scan → Create Challan.** Security selects
the packing list (Mode `LOAD`), scans the cartons onto the truck and
submits `ZSOL_DISPATCH_ISCAN_SRV` IscanSet exactly as before (Boxno, So,
So_Item, Pck_lst, Status `S`; that service is unchanged). Create Challan
then offers the lists with a confirmed carton (Mode `CHALLAN`) and
`ZCL_ZSOL_OBD_CREATE` packs **only the confirmed cartons** onto the
delivery; unconfirmed ones are reported `W` and stay on the list for a
later Challan; a list with none confirmed posts nothing.

A carton is *confirmed* when `ZSOL_HUDISPATCH` has its row (the table is
keyed on `BOXNO`; a scan rewrites the row) with `STATUS <> 'E-'` (the
dispatch service's mark for a scan whose order/item did not match
`ZPP_PACK`), `PCK_LST` = the carton's packing list and `ERDAT >=
ZPP_PACK-PLDATE`. The rule is written twice, identically — in the DPC
(what the screens show) and in `ZCL_ZSOL_OBD_CREATE` (what posts). Change
one, change both. ZSDOBDN has always insisted on the Security scan before
the Challan for `ZSOL_LOCKDIS` plants; this restores that order for the
app, for every plant.

Front-end: `index.html` Security Loading module reads
`PackingListSet`/`PackingListBoxSet` instead of the delivery query; Create
Challan shows Confirmed / "Not confirmed - stays on list" per carton and
weighs the confirmed ones; tiles reordered. Test:
`test/security_first_test.js`. The old front-end still works against this
backend (no `Mode` = every pending list); this front-end needs this
backend (`$filter` on `Mode` is a 400 against the old model) — both halves
are on KSDK906943.

### SOCHG on the Packing List (07.09.2026, KSDK906946)

A user holding **SOCHG** gets two more things on the Packing List: a *Select
a Whole Lot* card (one chip per batch among the available boxes; a tap
selects every box of the lot that fits) and a tolerance of **10% of the
item's order quantity** when that is more than ZSDTOL — the dyeing plant
sells one lot per item and the next lot has to go on whole. The screen's
`capFor()` and the upload's `POST_BOX` apply the same rule; the DPC tells
the report who is asking through the `ZSOL_SOCHG` memory flag. A plain
picker and SOLSYNCH's scanner see no change.

`App = 'X'` (per-box log only) is unchanged and still used by SOLSYNCH's
Android scanner. Every call carries the `X-Scan-Token` header and is
checked by `ZCL_ZSOL_APP_AUTH=>CHECK_REQUEST`; the POST needs feature
`CHALLAN`.

```
GET  ZSOL_SCAN_READ_SRV/ZSOL_RESERVATION                 rsnum, rspos, bwart, matnr, maktx, werks, lgort, umwrk, umlgo, open_qty, meins, rsdat, bdter, wempf, sgtxt

GET  ZSOL_SCAN_READ_SRV/ZSOL_SO_BOXCHECK?$filter=vbeln eq '5125000098'
     one row per item: vbeln, posnr, matnr, arktx, werks, lgort, charg, kwmeng, vrkme, dis_qty, open_qty, abgru,
     zzsize/zzsiz1/zzsiz2, zzgrade/zzgrad1/zzgrad2, so_batches ("B1; B2"), batch_src (A assigned / C item / blank),
     cand_cnt, match_cnt, match_wt, need_batch ("BATCH×n (kg KG); …"), other_lgort, other_size, other_grade,
     other_so ("VALUE×n; …"), on_deliv, not_posted, hint (one sentence for the operator)
GET  ZSOL_SCAN_READ_SRV/ZSOL_SO_BATCH?$filter=vbeln eq '…'    the ZVBAP_BATCH rows of the order
POST ZSOL_SCAN_READ_SRV/ZSOL_SO_BATCH   { vbeln, posnr, charg }          needs SOCHG; batch must be packed in-stock HU of the item's material/plant;
                                                                          item with a single VBAP-CHARG: that batch is REPLACED (v5; v4 refused)
DELETE ZSOL_SCAN_READ_SRV/ZSOL_SO_BATCH(vbeln='…',posnr='…',charg='…')   needs SOCHG; the item's single VBAP-CHARG is CLEARED when named (v5)
```

Note the `$filter` value for `vbeln` is the 10-character order number
(`'5125000048'`); the 13-character padded form fails the facet check.

The reads are session-scoped (the caller must hold the order's company
code / a plant of the order); the writes additionally need the `SOCHG`
feature and refuse service users (ISCAN_APP) outright.

### QC Post Dyeing / Post Winding list the waiting job cards (07.09.2026, KSDK906946 front-end only)

Both production QC screens now open with **Job Cards Waiting for Dyeing / Winding QC**, read from `ZSOL_JOBCARD` (`werks`, `days`; default plant 2002, 45 days). The screen decides the stage from the row itself, so no backend change was needed:

| Card shows up on | Rule on the `ZSOL_JOBCARD` row |
|---|---|
| QC Post Dyeing | `closed` blank **and** `dyeing_date` blank (operation 0010 not confirmed) |
| QC Post Winding | `closed` blank **and** `dyeing_date` set **and** `winding_date` blank (0010 confirmed, 0020 not) |

A tap puts the job card number in the scan field and runs the same `QcLotSet` lookup a barcode scan does (`itype` D / W, `scan` = job card). After a successful `QcConfirmSet` the list is re-read, so the card has left the dyeing list and appears on the winding list. `zcl_zsol_prod_jobcard.abap` is the class that fills `dyeing_date` / `winding_date` from the confirmations (unchanged here). Test: `test/qc_pending_test.js`. Operator manual for WIP Batch, Job Card and the three QC screens: `docs/Dyeing-Production-QC-Operator-Manual.pdf`.

## Deploy / transport

1. `npm run deploy` in `apps/zsol_scan_suite` (ui5-deploy.yaml points at **KSDK906946** — tap-to-replace, whole-lot selection and the SOCHG headroom; activate `ZRPT_SALES_UPLOAD_FR` in Eclipse first, see its row above).
2. KSDK906917 and KSDK906920 (tasks KSDK906921/906922) are released — import KSQ in that order, then KSP.
3. KSDK906923 (table `ZSOL_SOBATCH_LOG`, class v4, DPC, `ZRPT_SALES_SCAN_FR` fix) and KSDK906943 (the three Challan classes, roll counting on the screen, Security-before-Challan) are released — import in that order. KSDK906946 (task KSDK906947: `ZCL_ZSOL_SO_BOXCHECK` v5, `ZCL_PICKUPLOAD_DPC_EXT`, `ZRPT_SALES_UPLOAD_FR`, this front-end) follows once the include is activated. Files in this folder are the KSD sources of all of it.
4. Classic V2 services already registered in all three systems. If the new entity sets do not show in `$metadata` after import, `/IWFND/CACHE_CLEANUP` for `ZSOL_SCAN_READ_SRV` (on KSD they appeared without it — `GET_LAST_MODIFIED` was bumped).
5. Per system: grant `SOCHG` to the supervisors who may name batches on orders (Users screen); nobody has it by default. On KSD only ADMIN holds it.
