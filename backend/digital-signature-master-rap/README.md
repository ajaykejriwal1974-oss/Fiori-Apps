# Digital Signature Master (ZDIGI) — managed RAP over `ZTDIGI_SIGN`

Custom master (KEJRIWAL Z-portfolio, `CUS`). Built as a **managed RAP**
business object **mapped onto the existing legacy table `ZTDIGI_SIGN`** —
no new persistence is created. The Fiori Elements *Manage* app is generated
from the service binding via the metadata extension `zc_digital_signature.ddlx`.

> **Fields are refit to the real Z-table** (from the field dictionary):
> data elements, types, lengths and the key mirror the legacy table. Wire
> value helps (reuse `ZSOL_F4*`) and confirm before activating.

## Fields (from the field dictionary)

| CDS element | Table column | Key |
|---|---|:--:|
| `CompanyCode` | `BUKRS` | 🔑 |
| `Email` | `EMAIL` |  |
| `Password` | `PWD` |  |
| `IpAddress` | `IP` |  |
| `PfxPrefix` | `PFX` |  |
| `SourceFolder` | `SOURCE_FOLDER` |  |
| `DestinationFolder` | `DEST_FOLDER` |  |

## Objects in `src/`

| File | Object | Role |
|---|---|---|
| `zi_digital_signature.ddls.asddls` | `ZI_DigitalSignature` | Interface CDS over `ztdigi_sign` |
| `zc_digital_signature.ddls.asddls` | `ZC_DigitalSignature` | Projection (`transactional_query`) |
| `zi_digital_signature.bdef.asbdef` | Behavior (managed) | create/update/delete, mapping |
| `zc_digital_signature.bdef.asbdef` | Projection behavior | use create/update/delete |
| `zbp_i_digital_signature.clas.*` | Behavior pool | `setDefaults` + `validateKey` |
| `zc_digital_signature.ddlx.asddlxs` | Metadata ext | Fiori Elements List Report / Object Page |
| `zui_digital_signature.srvd.srvdsrv` | Service def `ZUI_DIGITAL_SIGNATURE` | exposes `ZC_DigitalSignature` |

## Create in ADT
- The table `ZTDIGI_SIGN` **already exists** — the managed BO binds to it
  as `persistent table ztdigi_sign`. No DDIC table to create.
- Key: `BUKRS`.
- This legacy table has **no TIMESTAMPL column**, so the optimistic-
  concurrency ETag is omitted; `lock master` still applies. Add a
  TIMESTAMPL column if optimistic locking is required.
- Create the OData V4 UI service binding `ZUI_DIGITAL_SIGNATURE_O4` in ADT.

## Branch
Tracked on `claude/fiori-app-extensions-h1nb64`.
