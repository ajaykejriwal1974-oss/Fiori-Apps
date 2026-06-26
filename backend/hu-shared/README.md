# Shared Handling-Unit read models (audit P3)

**Consolidation P3** of the [custom-app audit](../../docs/CUSTOM-APP-AUDIT.md):
the HU/packing services used to each re-declare a near-identical read over the
standard HU tables. The VEKP/VEPO read + casts now live **once** here; each
service's interface view is a thin projection over one of these bases.

| Shared view | Source | Consumed by |
|---|---|---|
| `ZI_HU_ItemBase` | `VEPO` ⋈ `VEKP` (item granularity) | `packing-detail-rap` (`ZI_PackingItem`), `goods-movement-hu-rap` (`ZI_HU_Item`), `hu-unpack-rap` (`ZI_HuUnpackItem`) |
| `ZI_HU_HeaderBase` | `VEKP` (header granularity) | `packing-hu-rap` (`ZI_Packing_Unit`), `hu-inbound-rap` (`ZI_InboundHu`), `palletization-rap` (`ZI_Pallet`), `post-packing-gr-rap` (`ZI_PostPackGr`) |

Each consumer keeps its **own entity name, field subset, key, behavior and
action(s)** — only the underlying read is shared. Renames are done in the
projection (e.g. `Reference as InboundDelivery`, `HandlingUnit as Pallet`);
`packing-hu` filters `ReferenceObject = '01'`.

> Read-only basic interfaces (`define view entity`, not root) — no behavior, no
> service binding of their own. Change the VEKP/VEPO field/cast logic here once
> and every HU service follows.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
