# CI validation

[`validate.py`](validate.py) is run by the **Validate** GitHub Actions workflow
([`.github/workflows/validate.yml`](../.github/workflows/validate.yml)) on every
push and pull request, and can be run locally:

```bash
python3 ci/validate.py
```

It is **structural** validation only (stdlib Python, no SAP backend, no
dependencies):

| Area | Checks |
|---|---|
| **JSON** | every `*.json` / `*.change` / `manifest.appdescr_variant` parses |
| **XML** | every `*.xml` (views / fragments) is well-formed |
| **CDS / RAP** | balanced `{}` and `()`; no hyphen in object names; every service-exposed projection, `as projection on` target, behavior `implementation in class`, action `parameter`/`result` `ZD_*` entity, and composition/redirect target resolves; object names are globally unique |
| **ABAP** | balanced `CLASS`/`ENDCLASS` and `METHOD`/`ENDMETHOD` |
| **Apps** | manifest `sap.app.id` matches the `rootView`, i18n bundle, `Component.js`, and view `controllerName` namespaces |

> **Out of scope (needs an S/4HANA backend):** semantic CDS/ABAP activation,
> ATC checks, field-type resolution. Those run on the system during transport.
> The `REPLACE_WITH_*` placeholders and `TODO`/`VERIFY` markers are intentional
> and are **not** flagged by this validator.
