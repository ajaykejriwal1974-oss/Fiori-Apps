# Backend design notes

One file per service/app, carried over from the old `backend/<app>-rap/README.md`
files when that parallel source tree was removed (Aug 2026).

**These are design notes, not source.** They describe the intent, the legacy
Z-transactions being replaced, the target tables and the actions — some of it
was implemented differently on KSD, and some was never implemented at all. The
authoritative ABAP is `backend/src/`, which mirrors package `ZKGPL_FIORI` on the
live system.

Where a note and `backend/src/` disagree, `backend/src/` wins.
[`../KSD-vs-repo-comparison-2026-08-19.md`](../KSD-vs-repo-comparison-2026-08-19.md)
lists the disagreements object by object.

Notable: `gate-pass-rap.md` describes an app that exists **nowhere** on KSD — the
live gate-pass service is the separate `ZC_GTPASS` / `ZI_GTPASS` implementation.
