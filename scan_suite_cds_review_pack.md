# Scan Suite CDS Adoption — Review Pack (QC read layer)
**Draft for review. NOTHING has been created or changed on any system.**
_2026-09-13. Files in this pack: `ZC_QC_INSP_CHAR_SCAN.asddls`, `ZCL_ZSOL_QC_SCAN_list_chars_revised.abap`._

---

## ⚠️ Connection note — read first

The ADT connection is currently pointed at **KSP (192.168.0.20:8002 = production)**.
I did **not** create or change anything there — production stays read-only.

To create this on **KSD** for review, connect the MCP to KSD (192.168.0.19:8000)
and tell me; I'll then create the CDS **inactive** and stage the engine change for
you to review in ADT and activate yourself. (Or paste the two source files below
into ADT directly — they are complete and paste-ready.)

---

## What this does

Moves the fragile stage `CASE` — the code behind the "7 of 11" bug — out of ABAP
and into a CDS field. The engine reads the stage from the view instead of computing
it. **No app change, no OData service regeneration, no frontend redeploy.** The
service contract (`ZSOL_QC_SCAN_SRV` / `QcCharSet`) and the save path are untouched.

```
BEFORE:  DB (ZC_QC_INSP_CHAR)  ->  ABAP CASE decides D/W  ->  filter  ->  QcCharSet
AFTER:   DB (ZC_QC_INSP_CHAR_SCAN, Stage derived in CDS)  ->  WHERE stage = kind  ->  QcCharSet
```

Why this slice: it directly hardens the exact code that broke, it's tiny and
reversible, and it introduces the CDS pattern with zero risk to the live handheld.

---

## Change 1 — new CDS view `ZC_QC_INSP_CHAR_SCAN`  (file: ZC_QC_INSP_CHAR_SCAN.asddls)

A `define view entity` selecting from the existing `ZC_QC_INSP_CHAR`, exposing the
same fields the engine reads plus a derived `Stage` (D/W) built with a CDS `CASE`.
Auth check is set to `#CHECK` (not `#NOT_REQUIRED`) — one of the config gaps the
audit flagged, fixed here at the source.

Package `ZSOL_ISCAN`, on a **fresh** transport (do not reopen a released one).

## Change 2 — `ZCL_ZSOL_QC_SCAN.LIST_CHARS`  (file: ...list_chars_revised.abap)

Diff vs the version live today:

```
- SELECT ... FROM zc_qc_insp_char
-   WHERE inspectionlot = @lv_lot
-   ORDER BY operationnumber, characteristicnumber INTO TABLE @DATA(lt_db).
- LOOP AT lt_db ...
-   CASE to_upper( <db>-mastercharacteristic ).       "  <-- the 20-line CASE
-     WHEN 'CDELTA' OR ... .  lv_stage = 'D'.
-     WHEN 'DENIER' OR ... .  lv_stage = 'W'.
-     WHEN OTHERS.            CLEAR lv_stage.
-   ENDCASE.
-   IF lv_kind = 'D' AND lv_stage <> 'D'. CONTINUE. ENDIF.
-   IF lv_kind = 'W' AND lv_stage <> 'W'. CONTINUE. ENDIF.
-   APPEND VALUE ts_char( ... stage = lv_stage ... ).

+ SELECT ..., stage                                    "  <-- stage now from CDS
+   FROM zc_qc_insp_char_scan
+   WHERE inspectionlot = @lv_lot
+     AND ( @lv_kind = ' ' OR stage = @lv_kind )        "  <-- filter pushed to DB
+   ORDER BY operationnumber, characteristicnumber INTO TABLE @DATA(lt_db).
+ LOOP AT lt_db ...
+   APPEND VALUE ts_char( ... stage = <db>-stage ... ). "  <-- no CASE, no CONTINUE
```

`lv_stage` is gone. Output structure `ts_char` is unchanged, so the OData response is
byte-for-byte the same shape the app already renders and saves.

### Behaviour parity check
- `kind = 'D'` → only colour chars (old: CASE→D + CONTINUE; new: `WHERE stage='D'`). ✔ same
- `kind = 'W'` → only physical chars. ✔ same
- `kind` blank → all chars. ✔ same (`@lv_kind = ' '` branch)
- Unknown MIC → `Stage=' '`, excluded from D and W panels. ✔ same as old `CLEAR lv_stage`

---

## Optional, more durable: MIC → stage as master data

Instead of the `CASE`, join a tiny mapping table `ZQC_MIC_STAGE (mic, stage)` in the
CDS. Then a new characteristic is added by inserting a row, **never** a code change or
transport. This is what would have prevented the original bug outright. Recommended
if the MIC set changes with any regularity. (CDS becomes
`... as select from ZC_QC_INSP_CHAR inner join zqc_mic_stage on ... { ..., zqc_mic_stage.stage as Stage }`.)

---

## Fuller path (NOT recommended as step 1): publish the CDS + repoint the app

Publishing `ZC_QC_INSP_CHAR_SCAN` as its own OData and pointing the app at it is the
"pure CDS" endpoint, but it is more work and more risk here, because:

- The app reads **snake_case** properties (`inspection_lot`, `mean_value`, `itype`)
  and a set named `QcCharSet`; a raw published CDS exposes CamelCase element names
  and a set named after the entity — so `renderChars` would break unless every
  element is aliased and the set renamed.
- The app **saves** results back through `ZSOL_QC_SCAN_SRV`; a read-only CDS can't
  take the write, so that service stays anyway.

So the app change would be two `get()` URLs (below) **plus** element aliasing **plus**
keeping the save on the old service — net more churn than Change 1+2 for the same
read benefit. Recorded here for completeness only:

```
// index.html loadChars()  (~line 8101)
- get("/QcCharSet?$filter=inspection_lot eq '"+odataStr(lot.inspection_lot)+"' and itype eq '"+kind+"'&$format=json", ...)
+ get("<new CDS service>/ZC_QC_INSP_CHAR_SCAN?$filter=InspectionLot eq '"+odataStr(lot.inspection_lot)+"' and Stage eq '"+kind+"'&$format=json", ...)

// index.html loadLot()  (~line 8299) — Inspection Results panel, no stage filter
- get("/QcCharSet?$filter=inspection_lot eq '"+odataStr(lotNo)+"'&$format=json", ...)
+ get("<new CDS service>/ZC_QC_INSP_CHAR_SCAN?$filter=InspectionLot eq '"+odataStr(lotNo)+"'&$format=json", ...)
```

---

## Recommended sequence

1. Connect MCP to **KSD**.
2. Create `ZC_QC_INSP_CHAR_SCAN` (inactive) on a fresh transport in `ZSOL_ISCAN`; syntax-check.
3. Apply the revised `LIST_CHARS`; syntax-check. Leave both **inactive** for your review.
4. You review in ADT → activate both.
5. Test on KSD: Post-Dyeing = 5 colour chars, Post-Winding = 11 physical chars, a save still posts. Compare row counts to the current lot output.
6. Release the transport → import to KSP. No frontend redeploy needed.
7. (Optional) swap the CDS `CASE` for the `ZQC_MIC_STAGE` mapping table.
