# Scan Suite deep audit — code + live browser
**2026-09-14 · frontend `apps/zsol_scan_suite/index.html` · backend KSDK907025 objects · Chrome (KSP prod tab read-only, KSD fresh tab)**

## Verdict

Code is clean and consistent with the repo; backend passes ATC and all unit tests.
The audit found **two real defects in the new frontend features — both fixed** in
`v2026.09.14.2`, now on the Mac. The single operationally important finding:
**neither UI batch is deployed anywhere yet** — KSD and KSP both still serve the
old KSDK907021 build. One `npm run deploy` ships everything.

## Code audit

**Repo integrity.** Working copy = GitHub HEAD (`6a0f124`) + exactly the two UI
batches made this session — every diff hunk accounted for, no foreign edits.
(The earlier "149-byte mystery" was a measurement artifact: JS string length
counts characters, the file size counts UTF-8 bytes; the multi-byte `·` glyphs
explain the difference exactly.)

**Automated checks.** Inline script parses clean. No duplicate DOM ids. All new
UI text is set via `textContent` (no injection surface). `setInterval`/`clearInterval`
balanced (retry timer self-clears; version check interval is intentional). Zero
unescaped `innerHTML` concatenations found; templates route through `esc()`.

**Defect 1 (fixed): version check dropped `sap-client`.** The update-banner
refetch used `location.pathname` only, losing `?sap-client=500`. On a client
mismatch the refetch bounces to a login page, the stamp regex finds nothing, and
the banner silently never fires. Fix: the refetch now preserves the page's own
query string.

**Defect 2 (fixed): stale-payload race in the retry queue.** Sequence: save
fails offline → queued with a snapshot → connection returns → operator re-saves
the row directly (success, possibly a *corrected* value) → 20 s retry timer
fires → the queued **old** value posts and overwrites the newer result. Fix: any
terminal outcome of a fresh save (success or refusal) now dequeues that row's
pending retry first. In-flight retries can't be recalled, but the window is a
single request.

**Backend.** ATC: **0 findings** on `ZCL_ZSOL_QC_SCAN`, `ZC_QC_INSP_CHAR_SCAN`,
`ZQC_MIC_STAGE`. Unit tests: **6/6 green** (re-run today). Transport KSDK907025
object list still exactly the four intended objects.

## Live browser audit

**KSP (production, existing tab — read-only probes only).** Serves the
pre-banner build; none of the new feature code present; app idle on the home
screen. Expected: KSDK907024 is not imported. No interaction was made with the
production tab.

**KSD (fresh tab, `192.168.0.19:8000`).** Also serves the **pre-banner build** —
fingerprinted as the KSDK907021 deploy (pending-list Export, Dyeing-Packing
Export and Print Recipe present; no version stamp, no spec-check, no retry
queue). Conclusion: **both UI batches exist only on the Mac.** Meanwhile the
KSD *backend* is already on the CDS stage path — safe by design (the OData
contract is unchanged), and the green unit tests prove the served read path.

## Actions

1. **Deploy** (you): `npm run deploy` from `apps/zsol_scan_suite` → KSDK907024.
   Ships batch 1 + batch 2 + both audit fixes as `v2026.09.14.2` in one go.
   One last manual hard-reload on the handhelds; the banner takes over after.
2. Smoke-test on KSD: spec-check tint, `x/y` badge, Record guard, Wi-Fi-off
   save → queue → flush, reload → Resume chip.
3. Release **KSDK907024** → import to KSP (backend + app together).
4. Commit + push the repo so GitHub matches the deployed code.
