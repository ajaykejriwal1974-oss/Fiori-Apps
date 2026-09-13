# Dyeing Packing — transactional app for plant 2002 (status 07.09.2026)

Pack a dyed 2002 batch into cartons from the Scan Suite, creating the **same
`ZPP_PACK` boxes the legacy T-code `ZPP_PACK_MODULE_DYING` makes**, so both tools
are usable in 2002 and every carton feeds the existing Packing List → Security →
Create Challan flow.

Decisions: ZPP_PACK cartons (not standard HUs); entry = scan the dyed batch;
surface = a Scan Suite tile + guarded OData V2 service.

## Create contract — verified against live 876x boxes of plant 2002
| Field | Rule |
|---|---|
| `boxno` | number range object **`ZHU_VEKP`**, range **`40`** (876x). `exidv` = boxno, zero-padded to 20. |
| `gjahr` | **Indian FY (Apr–Mar)** of the pack date — today → **2026**. |
| `werks/auart/ptype/enduse/lgort/head` | `2002` · `KID` · `01` · `D` · `UDL1` · blank |
| `mergno/aufnr/matnr` | from `ZPP_BATCHN` (merge = batch no, order, dye_code) |
| `netwt/tarewt/grosswt/spoolno` | operator: net + tare → gross = net+tare; cones |
| status flags | `pklst 000000`, `vbeln/posnr` blank, `plist/posted/hupost/conind/repack` blank |

## DONE on KSD (transport KSDK906946, package ZSOL_ISCAN) — all active

**Engine**
- `ZCL_ZSOL_DYE_PACK` — create engine (`defaults_for`, `build_row`, `create_box`
  with `iv_test` simulate). Draws boxno from ZHU_VEKP/40, INSERTs ZPP_PACK, logs
  ZSOL_SOBATCH_LOG action `P`.
- `ZCL_ZSOL_DYE_PACK_TEST` — 7 ABAP-Unit tests green (incl. live test-mode create).

**OData service `ZSOL_DYE_PACK_SRV`** (hand-written V2, mirrors the QC service)
- `ZCL_ZSOL_DYE_PACK_MPC` — model. Sets:
  - `DyeBatchSet`   GET  — screen defaults for a dyed batch.
  - `DyePackBoxSet` GET  — cartons packed for a batch this FY; POST — pack a carton.
- `ZCL_ZSOL_DYE_PACK_DPC` — provider. Guarded by `ZCL_ZSOL_APP_AUTH`: every call
  needs a valid app session + the batch's plant (2002) in the caller's scope;
  the **POST additionally needs the `DYEPACK` screen grant**. Delegates to the engine.

## TO DO
1. **Register the service** (one-time, admin — same as the QC service):
   - `/IWBEP/REG_MODEL`  → model `ZSOL_DYE_PACK_MDL` v1 → MPC `ZCL_ZSOL_DYE_PACK_MPC`.
   - `/IWBEP/REG_SERVICE` → service `ZSOL_DYE_PACK_SRV` v1 → DPC `ZCL_ZSOL_DYE_PACK_DPC`;
     **save first, then Assign Model**.
   - `/IWFND/MAINT_SERVICE` → Add Service → alias `LOCAL` → add `ZSOL_DYE_PACK_SRV`;
     ICF node = **"SAP Gateway OData V2"** (not "None").
   - Verify: `GET /sap/opu/odata/sap/ZSOL_DYE_PACK_SRV/$metadata` returns 200.
   - On KSP later: the same, plus the nginx allowlist line for the service path.
2. **Grant `DYEPACK`** to the packing operators (Scan Suite user admin), and add
   `DYEPACK` to the feature catalog in the ADMIN screen / index.html.
3. **Frontend** — `screen-dyepack` + tile: scan batch → `DyeBatchSet` defaults →
   carton entry (net, tare, cones; gross auto) → POST `DyePackBoxSet`; running list
   from `DyePackBoxSet` GET + totals; 2002-scoped. Playwright test.
4. **Deploy** (`npm run deploy`, KSDK906946).

## Frontend contract (for the screen)
- Defaults:  `GET ZSOL_DYE_PACK_SRV /DyeBatchSet?$filter=batchno eq '2120000023'`
- Pack:      `POST ZSOL_DYE_PACK_SRV /DyePackBoxSet`
  body `{ Batchno, Netwt, Tarewt, Spoolno, Grade, Psize, Remks }`
  → returns `{ Boxno, Gjahr, Grosswt, Success, Message }`
- Session boxes: `GET /DyePackBoxSet?$filter=batchno eq '2120000023'`
- X-Scan-Token header is added automatically by the app's Api layer.

## UPDATE — folded into ZSOL_SCAN_READ_SRV (no registration needed)

Decision: instead of registering a separate service, the packing sets were folded
into the already-registered read service, exactly like the QC screens. So there is
**no service registration on KSD or KSP** — packing ships with `npm run deploy` only.

Done on KSD (transport KSDK906946), both classes active:
- `ZCL_ZSOL_SCAN_READ_MPC` — added `def_dyepack_sets` defining `DyeBatchSet` +
  `DyePackBoxSet` (structures/constants reused from `ZCL_ZSOL_DYE_PACK_MPC`);
  metadata timestamp bumped so the new sets appear.
- `ZCL_ZSOL_SCAN_READ_DPC` — added `dyepack_get` (GET DyeBatchSet / DyePackBoxSet)
  and `dyepack_create` (POST DyePackBoxSet), guarded by `ZCL_ZSOL_APP_AUTH`
  (session + plant 2002; POST needs `DYEPACK`), delegating to the engine
  `ZCL_ZSOL_DYE_PACK`. Mirrors the QC `qc_get`/`qc_create` delegation.

Frontend calls now target **ZSOL_SCAN_READ_SRV** (not a separate service):
- `GET  ZSOL_SCAN_READ_SRV /DyeBatchSet?$filter=batchno eq '<batch>'`
- `POST ZSOL_SCAN_READ_SRV /DyePackBoxSet`  body { Batchno, Netwt, Tarewt, Spoolno, Grade, Psize, Remks }
- `GET  ZSOL_SCAN_READ_SRV /DyePackBoxSet?$filter=batchno eq '<batch>'`

Vestigial now (built earlier, unused): `ZCL_ZSOL_DYE_PACK_DPC` and the never-registered
service `ZSOL_DYE_PACK_SRV` — can be deleted; `ZCL_ZSOL_DYE_PACK_MPC` is KEPT (its
structures + gc_set constants are reused by the read service).

Still to do: (1) grant `DYEPACK` + add it to the feature catalog; (2) build the
`screen-dyepack` tile; (3) `npm run deploy` (KSDK906946).
