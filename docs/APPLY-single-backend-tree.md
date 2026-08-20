# Apply the "one ABAP source tree" change

I could not push to GitHub from this session — the git proxy refused
(`ajaykejriwal1974-oss/Fiori-Apps is not in this session's authorized repository
set`). So the commit is delivered as a **git bundle** instead. Applying it gives
you exactly the branch I would have pushed, commit hash `5252ebd`.

## Apply

```bash
cd ~/Fiori-Apps

# make sure you are on the commit the branch was built from, with a clean tree
git status                      # should be clean
git rev-parse main              # should be 29ab372fef74ad32c985b4dad616d71d81bdfa22

git fetch docs/single-backend-tree.bundle chore/single-backend-tree:chore/single-backend-tree
git switch chore/single-backend-tree

python3 ci/validate.py          # expect: ✅ Validation passed
```

Then review, and when you are happy:

```bash
git switch main
git merge --ff-only chore/single-backend-tree
git push origin main            # from your Mac, where credentials work
```

To throw it away instead: `git branch -D chore/single-backend-tree`.

## What the commit does

| | |
|---|---|
| Removes | the 31 `backend/<feature>/` folders — 276 files |
| Promotes | `backend/_abapgit_import/src/` → `backend/src/` — 1155 files, renames only |
| Rewires | `.abapgit.xml` `STARTING_FOLDER` → `/backend/src/` |
| Fixes | `ci/validate.py` — drops `MIRROR_DIRS`, and teaches it `define root custom entity` |
| Preserves | every folder's design prose as `docs/backend-notes/<folder>.md` (32 files, 68 KB) |
| Retargets | every link to the old paths across README, docs/ and apps/ — 0 broken links after |
| Adds | `docs/KSD-vs-repo-comparison-2026-08-19.md` |

Net: **1492 files changed, 405 insertions, 5851 deletions.**

## Verification already done

- `backend/src` matches live KSD 1:1 on every readable object type — 148 DDLS,
  61 BDEF, 33 SRVD, 28 CLAS, 17 DDLX, 2 PROG, with **zero** repo-only and
  **zero** live-only names. Nothing that runs on KSD was lost.
- `ci/validate.py` passes on the new tree (77 JSON, 19 XML, 259 CDS/RAP, 28 ABAP).
- No dangling references to the removed paths; no broken relative Markdown links.

## What you are giving up

These lived **only** in the deleted folders and are **not** on KSD. They stay in
git history at `29ab372` and are catalogued in the comparison doc, so any of them
can be lifted back out later:

1. **The `_Item` composition action parameters** (13 child entities + 13 rewritten
   action imports) — the 3 Aug performance work. KSD still uses the flat
   `char(1333)` delimited-string variant.
2. **Semantic typing** — `abap.quan` + `@Semantics.quantity.unitOfMeasure` and
   `abap.curr` + `@Semantics.amount.currencyCode` on ~12 views, where live still
   casts to `abap.dec`.
3. **The Gate Pass RAP app** (11 objects). Note the live system already runs a
   separate `ZC_GTPASS` / `ZI_GTPASS` gate-pass service, so this was a second
   implementation of the same thing.
4. Ten `ZBP_I_*` behaviour-pool classes for master-data apps whose BDEFs exist
   live but whose implementation classes do not.

Nothing here was working in production — items 1 and 2 are improvements that were
never deployed, items 3 and 4 were never deployed at all.
