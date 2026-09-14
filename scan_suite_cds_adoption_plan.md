# Scan Suite — CDS Adoption Plan (read layer)
**KGPL Scan Suite · package ZSOL_ISCAN · KSD → transport → KSP · plant 2002**
_Prepared 2026-09-13. Advisory — no production changes made._

---

## TL;DR

The Scan Suite's QC **data** is already sitting on a modern CDS foundation:
`ZI_QC_INSP_CHAR` → `ZC_QC_INSP_CHAR` is a proper `define view entity` projection.
The only hand-coded part left is the **stage-derivation / kind-filter wrapper** in
`ZCL_ZSOL_QC_SCAN` (`LIST_CHARS`) — the ABAP `CASE` on the MIC code that decides
`'D'` (colour) vs `'W'` (physical). That is exactly the code that broke as the
"7 of 11" bug and that we patched this session.

So "adopt the better pattern" for QC reads is not a rewrite — it's **pushing that
one CASE down into CDS** and letting the app query the view directly. Writes stay
where they are (RAP behavior). This is the low-risk, high-value slice.

Two paths are laid out below. **Recommendation: Path A** (CDS read retrofit inside
the Scan Suite) now; keep Path B (converge on the V4 `zui_qc_inspection` app) as the
longer-term option, and pick one — do not run both.

---

## What is already CDS vs still hand-coded

| Layer | Today | Verdict |
|---|---|---|
| QC char data | `ZI_QC_INSP_CHAR` → `ZC_QC_INSP_CHAR` — `define view entity` (V4-style) | Already modern. Reuse. |
| Stage (D/W) + kind filter | `ZCL_ZSOL_QC_SCAN.LIST_CHARS` — ABAP `CASE` on `MasterCharacteristic` | **The thing to move to CDS.** |
| Pending lists (Post-Dyeing/Winding) | ABAP SELECTs over job-card / batch views | Retrofit candidate (see §Path A step 5). |
| Result save / UD | RAP behavior `MODIFY ENTITIES OF zi_qc_insp_lot`, wrapped in the V2 service | **Leave as-is** — already RAP under the hood. |

Key point: the write path is already half-RAP, so retrofitting reads does not touch
posting logic at all.

---

## Path A — CDS read retrofit inside the Scan Suite (recommended, incremental)

### Step 1 — Add `Stage` as a declarative element (kill the ABAP CASE)

Today `LIST_CHARS` computes stage in ABAP:

```abap
" current, imperative:
CASE to_upper( ls_char-mastercharacteristic ).
  WHEN 'CDELTA' OR 'WASHFAS' OR 'LIGHTFAS' OR 'RUBDRY' OR 'RUBWET'.
    lv_stage = 'D'.
  WHEN 'DENIER' OR 'FILAMENT' OR 'TENACITY' OR 'NIPS' OR 'ELONGATN'
    OR 'OIL' OR 'PKGHAR' OR 'MOISTURE' OR 'PKG_LEN' OR 'PKG_WT'
    OR 'PKG_BILD' OR 'MOUST' OR 'PKGWT' OR 'LENGTH' OR 'PKG_DEN'.
    lv_stage = 'W'.
ENDCASE.
```

Move it into a consumption CDS as a calculated element. New view
`ZC_QC_INSP_CHAR_SCAN` (projection on the existing `ZC_QC_INSP_CHAR`):

```abap
@EndUserText.label: 'QC Char - Scan Suite consumption'
@AccessControl.authorizationCheck: #CHECK          " <-- auth ON (fix the gap)
define view entity ZC_QC_INSP_CHAR_SCAN
  as projection on ZC_QC_INSP_CHAR
{
  key InspectionLot,
  key OperationNumber,
  key CharacteristicNumber,
      MasterCharacteristic,
      CharacteristicName,
      CharacteristicUnit,
      DecimalPlaces,
      TargetValue,
      LowerLimit,
      UpperLimit,
      SelectedSet,
      MeanValue,
      ResultCode,
      DefectCount,
      Valuation,
      ResultStatus,
      // derived stage — declarative, replaces the ABAP CASE
      case upper( MasterCharacteristic )
        when 'CDELTA'  then 'D' when 'WASHFAS' then 'D'
        when 'LIGHTFAS' then 'D' when 'RUBDRY' then 'D' when 'RUBWET' then 'D'
        when 'DENIER'  then 'W' when 'FILAMENT' then 'W' when 'TENACITY' then 'W'
        when 'NIPS'    then 'W' when 'ELONGATN' then 'W' when 'OIL' then 'W'
        when 'PKGHAR'  then 'W' when 'MOUST' then 'W' when 'PKGWT' then 'W'
        when 'LENGTH'  then 'W' when 'PKG_DEN' then 'W'
        when 'MOISTURE' then 'W' when 'PKG_LEN' then 'W' when 'PKG_WT' then 'W'
        when 'PKG_BILD' then 'W'
        else ' '
      end                                as Stage
}
```

> **Better still (optional):** replace the `case` with a join to a small mapping
> table `ZQC_MIC_STAGE` (MIC → stage). Then adding a new characteristic never needs
> a code change or transport again — it becomes master data. This is what would have
> prevented the "7 of 11" bug entirely. Recommended if MICs change with any frequency.

### Step 2 — Publish the view as OData

Two options; pick to match how the app authenticates today (it uses the V2
`/sap/opu/odata/sap/...` base):

- **V2, least app change:** add `@OData.publish: true` to `ZC_QC_INSP_CHAR_SCAN`,
  then activate the generated service in `/IWFND/MAINT_SERVICE`. App keeps its V2
  base path.
- **V4, cleaner endpoint:** create a service definition + binding
  (`/sap/opu/odata4/...`). Better long-term, but the app's fetch base and CSRF
  handling change — more frontend work.

Given the Scan Suite is all V2 today, start with `@OData.publish: true`.

### Step 3 — Re-point the app read

In `index.html`, the char load currently calls the function/entity on
`ZSOL_QC_SCAN_SRV` and the app filters D vs W. Change it to read the new entity and
filter server-side:

```
GET /sap/opu/odata/sap/ZC_QC_INSP_CHAR_SCAN_CDS/ZC_QC_INSP_CHAR_SCAN
    ?$filter=InspectionLot eq '<lot>' and Stage eq 'W'      // Post-Winding
    &$orderby=OperationNumber,CharacteristicNumber
```

Post-Dyeing uses `Stage eq 'D'`. The D/W decision now lives in the `$filter`, not in
ABAP or JS. Delete the client-side stage filtering once this is in.

### Step 4 — Test each QC panel end-to-end (KSD first)

1. Post-Dyeing → a lot with colour chars → confirm **5** rows (`Stage eq 'D'`).
2. Post-Winding → a lot with physical chars → confirm all **11** rows (`Stage eq 'W'`).
3. QC Raw Material → confirm unaffected.
4. Save a result → confirms the **write path is untouched** (still RAP behavior).
5. Compare row counts against the old `LIST_CHARS` output for the same lots — must match.

### Step 5 — (Optional, same pattern) pending-list summaries

The Post-Dyeing/Post-Winding **pending** lists are ABAP SELECTs today. They are the
next-best retrofit: model them as a CDS with the joins + any `sum(...)`/`group by`
pushed to the DB (the `ZSOL_PLIST*` / `ZSOL_PLISTPEND_SUM` summary views in the
package are the shape to copy). Only do this after Step 1–4 are stable.

### Step 6 — Transport & config hygiene

- All new CDS + service go **KSD → transport → KSP** (never edit KSP directly).
- On every new/touched CDS: `@AccessControl.authorizationCheck: #CHECK` (not
  `#NOT_REQUIRED`), remove any dead commented-out joins, use `define view entity`
  (not `@AbapCatalog.sqlViewName` old-style).
- Bundle into a fresh transport (e.g. the next KSDK9070xx); do **not** reopen a
  released one.

### Rollback

The old `LIST_CHARS` path stays intact until Step 3 goes live. If a panel misbehaves,
revert the `index.html` read to the old service call (one frontend redeploy) — the
new CDS can sit unused with no effect on the running app.

---

## Path B — Converge on the V4 `zui_qc_inspection` app (bigger, cleaner endpoint)

Instead of modernizing the Scan Suite's QC in place, retire the Scan Suite QC tiles
and route users to the existing standalone V4 apps (`qc-post-dyeing`,
`qc-post-winding`, `qc-raw-material` — all on `zui_qc_inspection`).

- **Pro:** one modern codebase, no duplicate QC logic, full RAP.
- **Con:** the V4 apps must first reach feature parity with the Scan Suite (the
  export buttons, quantity prefill, blank-field behaviour, the aligned MIC set, the
  handheld UX). They do **not** currently carry the `LIST_CHARS` fix, because they
  don't call `ZCL_ZSOL_QC_SCAN`. Bigger project, and it changes what operators open.

---

## Decision

| | Path A (CDS in Scan Suite) | Path B (converge on V4) |
|---|---|---|
| Effort | Low — one CDS + re-point one read | High — parity build + rollout |
| Risk to live app | Low (rollback = 1 redeploy) | Medium/High (operators switch apps) |
| End state | Scan Suite modern reads, still V2 host | Single modern V4 QC, Scan Suite QC retired |
| Duplication | Removes ABAP shaping; Scan Suite stays | Removes the duplicate entirely |

**Recommended:** do **Path A** now (it directly hardens the code that caused the
7-of-11 bug and costs little), and treat **Path B** as the strategic option to decide
separately. **Do not do both and keep both live** — that recreates the two-of-everything
problem this audit flagged.

---

## Sequence summary

1. Create `ZC_QC_INSP_CHAR_SCAN` with a declarative `Stage` element (or a MIC→stage
   mapping table), auth check ON.
2. `@OData.publish: true`, activate the service.
3. Re-point the app's char read to the new entity with `$filter=... and Stage eq 'W'/'D'`.
4. Test all QC panels on KSD; confirm write path untouched.
5. (Optional) convert the pending-list summaries to CDS.
6. Transport KSD → KSP; keep auth on and dead code out.
