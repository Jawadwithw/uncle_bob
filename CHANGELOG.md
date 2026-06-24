# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0

### Added

- `uncle_bob init` — bootstrap core clean architecture layers in a Flutter project
- `uncle_bob feature <name>` — generate a full feature module (data / domain / presentation)
- `uncle_bob guide` — step-by-step walkthrough (`--feature` for questionnaire examples)
- Interactive API questionnaire with inline JSON examples
- Split response capture: base response, data, pagination (`paginationData` / `pagination`)
- Query params capture and generation in datasource `queryParameters`
- Reusable project defaults for base response and pagination (saved in `uncle_bob.yaml`)
- Paginated feature scaffolding (params, merge bloc, infinite scroll screen)
- `feature --no-prompt` with flags for CI/scripts
- `uncle_bob.yaml` project config
- Per-feature `*_api_contract.json` metadata files

### Notes

- `init` auto-adds required Flutter app dependencies via `flutter pub add` when possible
- Generated entities start with placeholder `id` + `name` — expand from your data example
