# KSDK906923 — done on KSD (06.09.2026)

Everything that used to wait here is active in KSD and its source now
lives one level up:

| Object | Now in | KSD state |
|---|---|---|
| Table `ZSOL_SOBATCH_LOG` | `../zsol_sobatch_log.tabl.asddls` | active |
| `ZCL_ZSOL_SO_BOXCHECK` v4 (log rows, VA02 single-vs-list rule, clean item numbers in messages) | `../zcl_zsol_so_boxcheck.abap` | active, tested: POST on item 20 of 5125000048 refused with "Item 20 already carries batch FD36010031 as its single batch …", nothing written |
| `ZCL_ZSOL_SCAN_READ_DPC` (passes the session user) | `../zcl_zsol_scan_read_dpc.abap` | active |
| Include `ZRPT_SALES_SCAN_FR` (per-item `ZVBAP_BATCH` read) | `../zrpt_sales_scan_fr.abap` | active, tested: 5125000048 165 → 174 lines after naming FC62000134 on item 30 |
| First `ZSOL_SOBATCH_LOG` row | — | 5125000048 / 000030 / FC62000134 / A / ADMIN / FIORI_USER / 06.09.2026 14:18:18 |

**This folder can be deleted** (including the stale
`zsol_so_batch_log.tabl.asddls` — the 17-character name was never created).

Still to do outside this folder: `npm run deploy` for `index.html` (the
card's single-batch gating), release KSDK906923, import KSQ after
KSDK906917 and KSDK906920, then KSP; grant `SOCHG` per system.
