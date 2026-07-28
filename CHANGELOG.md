# Changelog

## Unreleased — Backend mirrored to live KSD (21 Jul 2026)

Reconciled the **12 freestyle transactional RAP apps** in `backend/` with the
running system (**KSD**, client 500) after their behavior logic was implemented
and activated live. The repo previously held an **older generation** (composition
model: `ZI_HuUnpackItem` + `ZD_*_item` children, commit-based savers); live had
been rebuilt flat and renamed. All source below was pulled from live via ADT,
except the behavior BDEFs and behavior-pool CCIMP (not ADT-readable), which are the
activated handler code / reconstructed signatures.

- **Behavior pools (`ZBP_I_*` CCIMP)** — real BAPI action bodies, all with an
  **empty `save()`** (RAP commits; no `COMMIT WORK`/`BAPI_TRANSACTION_COMMIT`):
  HU Unpack (`BAPI_HU_UNPACK`), Batch Status (`BAPI_BATCH_RESTRICT`/`_DELETE`),
  Dispatch (`UPDATE zsol_hudispatch`), Goods Movement + Post Packing GR
  (`BAPI_GOODSMVT_CREATE`), HU Inbound (`BAPI_INB_DELIVERY_CONFIRM_DEC`), MTOS
  (`BAPI_GOODSMVT_CREATE` 411 E + `BAPI_MATPHYSINV_CREATE`), Palletization /
  Packing Detail / Packing Unit (`BAPI_HU_CREATE`/`_PACK`/`_REPACK`), Contract
  (`BAPI_SD_SALESDOCUMENT_CHANGE`), QM (unmanaged `update`+buffer →
  `BAPI_INSPOPER_RECORDRESULTS`).
- **Flat action params** — replaced the composition children with the live flat
  `ZD_*` imports (embedded `HuItemList` / `ItemList` / `HandlingUnitList` etc.);
  **deleted** the 10 stale `zd_*_item` / `_hu` / `_box` / `_unit` entities that do
  not exist on the live system.
- **Interface + projection CDS + service definitions** — overwritten with the
  live `ZI_*` / `ZC_*` / `ZUI_*` source.

> NOTE: BDEFs are reconstructed from the live action/alias signatures (ADT cannot
> read `.asbdef`); spot-check `strict` level against live if re-pulling. HU Unpack
> and Batch Status savers here are the **corrected** empty version — the live
> savers still carry `BAPI_TRANSACTION_COMMIT` and must be emptied on KSD.

## Unreleased — KEJRIWAL Z-to-Fiori extension package (initial)

Clean-core SAP Fiori extension package for the S/4HANA 2025 migration
(KSQ/KHQ, client 500), derived from `KEJRIWAL_Z_to_Fiori_Mapping.pdf`. Covers all
**Table B** items (standard app + extension) plus the supporting backend and the
delivery documentation. **Table A** (replace as-is) needs no code.

### Adaptation projects (UI extensions on standard apps)
- **F1873 Manage Sales Orders** — textile attributes section + custom column +
  controller extension (replaces ZVA01/ZVA01N, ZSOCLOSE).
- **F3069 Confirm Production Operation** — dyeing confirmation section + guards
  (replaces ZCO11N/ZCO11A).
- **F0867A Manage Outbound Deliveries** — delivery-challan section + column +
  Output-Management print trigger (replaces ZDEL).
- **Manage Sales Contracts** — custom status (close/release/complete) + pending
  rate (replaces ZCON_CLOSE/ZCOREL/ZCON02).

### Custom Fiori apps (new interaction models)
- **Record Inspection Results (Mass)** — multi-lot result entry (replaces ZQA32).
- **Post Goods Movement (HU / Box)** — scan-driven HU movement (replaces ZBOX_MOVE).
- **Dyeing Packing** — cone/carton/pallet HU structure (replaces ZPACK*/ZREPACKD).
- **Contract Batch Update** — mass batch assignment (replaces ZBATCH_CHANGE).

### Backend (RAP)
- **Shade Master** — managed RAP Custom Business Object (ZDD_SHADE); full source.
- **QM Mass Results**, **HU Goods Movement**, **Dyeing Packing**, **Contract Batch
  Update** — unmanaged RAP service skeletons over the standard QM/HU/MM/SD APIs.

### Docs
- `EXTENSIBILITY.md` (tier-1 vs tier-2 vs backend), `PUBLISHING.md` (deploy + FLP),
  `ACTIVATION.md` (Basis runbook ↔ repo + deploy order), `GO-LIVE-CHECKLIST.md`
  (per-app steps), `TRANSPORT-PLAN.md` (packages + transports DEV → KSQ → PROD).

### Status
UI artifacts and backend source are **authored and structurally validated**, with
`REPLACE_WITH_*` placeholders and `TODO`/`VERIFY` markers for live-system values
and BAPI wiring. Nothing has been run against KSQ yet — execution is gated on
Basis Rapid Activation of the base apps (see `docs/ACTIVATION.md`).
