# Changelog

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
