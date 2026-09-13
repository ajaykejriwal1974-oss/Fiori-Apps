# Launchpad tiles — bringing the nine into line

Against `docs/KSQ_FLP_Corporate_Design.pdf`. All of this is done in **Manage
Launchpad Pages** — no backend work, no transport.

## 1. Assign the page to a role — first, before anything else

`ZKIPL_CORRECTED_PG_PROD` shows **Not Assigned to Role**. Nine working tiles
that nobody in the plant can reach. Everything below is cosmetic until this is
done.

## 2. Subtitles — one pattern

The design note calls this "the single change with the biggest visual payoff for
the least effort", and the page currently carries five spellings of the same
idea: *Kejriwal master data*, *KEJRIWAL master data*, *KEJRIWAL Custom*,
*Kejriwal Custom*, *Kejriwal analytics*.

Pattern: **`Kejriwal – <Domain>`**, en dash, title case.

| Tile | Now | Set to |
|---|---|---|
| Job Master | Kejriwal master data | `Kejriwal – Master Data` |
| Schedule Master | Kejriwal master data | `Kejriwal – Master Data` |
| Recipe Master | Kejriwal master data | `Kejriwal – Master Data` |
| Label Master | KEJRIWAL master data | `Kejriwal – Master Data` |
| WIP Batch Close | KEJRIWAL Custom | `Kejriwal – Production` |
| Batch Status | KEJRIWAL Custom | `Kejriwal – Production` |
| Cancel Production Confirmation | KEJRIWAL Custom | `Kejriwal – Production` |
| Contract Batch Update | Kejriwal Custom | `Kejriwal – Sales` |
| WIP Batch | Kejriwal analytics | `Kejriwal – Analytics` |

"Custom" says nothing to the person reading it — every tile on this launchpad is
custom. The domain is what tells them whether the tile is theirs.

## 3. Sections — split the single block

One section of nine tiles is the flat list the design note is written against.
Three sections, matching the Space 1 layout in that document:

**Batch & Process Operations** — Batch Status · WIP Batch Close · Cancel
Production Confirmation

**Process Analytics** — WIP Batch

**Master Data** — Job Master · Schedule Master · Recipe Master · Label Master

Contract Batch Update belongs to **Sales & Compliance** (Space 3), not here. It
edits sales contracts; a dyeing operator has no business on that screen.

## 4. Where this deviates from the document, and why

The document puts the four master-data tiles in their own Space, assigned to a
small data-steward role. That is the right end state and the page above does not
reach it — it keeps them here in a Master Data section instead.

That is deliberate for now: the same person is doing both jobs, and moving them
before the roles exist would leave the tiles unreachable. Once a data-steward
role exists, lift that whole section into Space 4 and the page becomes exactly
what the standard describes.

Also missing from this page: **Raw Material QC, Post-Dyeing QC and
Post-Winding QC**, which the standard puts on this same Space under a Quality
Control section. They are deployed and working. Adding them makes this the
complete Production & Quality space rather than a partial one.

## 5. Worth doing once the structure is settled

- Consistent icon family per section, so the eye can scan the page.
- A dynamic tile on WIP Batch showing the open-batch count, rather than a static
  one. Plant 2002 alone has 131,555 open batches — a number on the tile would
  tell a supervisor something before they click.
- Turn off end-user Add/Move Tile on this page so everyone in the role sees the
  same layout.
