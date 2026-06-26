# Database table `zdd_shade` — DDIC field spec

Create this transparent table in ADT / SE11 (it is the persistence for the RAP
managed BO). Delivery class `A`, data maintenance `Display/Maintenance Allowed`.

| Field | Key | Data element / type | Description |
|---|---|---|---|
| `client`                | ✔ | `mandt` (CLNT 3)            | Client |
| `shade_code`            | ✔ | `char10`                   | Shade code (semantic key) |
| `shade_name`            |   | `char40`                   | Shade name |
| `color_family`          |   | `char20`                   | Colour family |
| `rgb_hex`               |   | `char6`                    | RGB hex (6 hex digits) |
| `lustre`                |   | `char10`                   | Lustre |
| `is_active`             |   | `abap_boolean` (CHAR1)     | Active flag |
| `created_by`            |   | `abp_creation_user`        | Created by (admin) |
| `created_at`            |   | `abp_creation_tstmpl`      | Created at (admin) |
| `last_changed_by`       |   | `abp_lastchange_user`      | Last changed by (admin) |
| `last_changed_at`       |   | `abp_lastchange_tstmpl`    | Last changed at (admin, total ETag) |
| `local_last_changed_at` |   | `abp_locinst_lastchange_tstmpl` | Local last changed at (instance ETag) |

Notes:
- The three `abp_*` timestamp/user data elements are the standard admin-field
  types managed RAP fills automatically (mapped via the `@Semantics` annotations
  in `ZI_DD_Shade`).
- `local_last_changed_at` is the ETag master used by the behavior definition.
- Prefer reusing a dedicated domain/data element for `shade_code`
  (e.g. `zdd_shade_code`) instead of a raw `char10` so it can carry a value help
  and search help consistently.
