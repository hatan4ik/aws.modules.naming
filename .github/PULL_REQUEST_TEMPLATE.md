## Summary

<!-- What changes and why. Link the issue this closes, if any. -->

## Type of change

- [ ] fix: bug fix, non-breaking
- [ ] feat: new optional input or output, non-breaking
- [ ] breaking: existing callers see different names, tags, or validation results (major release only)
- [ ] docs: documentation only
- [ ] chore: tooling, CI, or dependencies

## Checklist

- [ ] Tests added or updated, and `terraform test` passes in every touched directory
- [ ] `tests/golden_master.tftest.hcl` passes unchanged (it pins the names and tags of the live platform roots)
- [ ] `make check` passes locally
- [ ] Docs regenerated with terraform-docs (`make docs`) in every touched directory
- [ ] `CHANGELOG.md` `Unreleased` section updated
- [ ] No provider, resource, or data source added to the module
- [ ] Breaking changes documented in `docs/UPGRADE-<version>.md`
