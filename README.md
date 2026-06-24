# uncle_bob

[![pub package](https://img.shields.io/pub/v/uncle_bob.svg)](https://pub.dev/packages/uncle_bob)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

CLI scaffolding for opinionated Flutter clean architecture.

Named after [Uncle Bob](https://blog.cleancoder.com/) (Robert C. Martin) — less folder-wrangling, more feature work.

## Install

```bash
dart pub global activate uncle_bob
```

Ensure `$HOME/.pub-cache/bin` is on your `PATH`, then:

```bash
uncle_bob --help
```

For local development:

```bash
dart pub global activate --source path /path/to/uncle_bob
```

## Quick start

```bash
cd my_flutter_app
uncle_bob guide          # optional walkthrough
uncle_bob init           # bootstrap lib/core + uncle_bob.yaml
uncle_bob feature organizations
```

`init` scaffolds core layers and tries to add required app dependencies via `flutter pub add`.

## Commands

### `guide`

```bash
uncle_bob guide
uncle_bob guide --feature
```

### `init`

Bootstraps once per project:

- `uncle_bob.yaml`
- `lib/core/` — failures, use cases, `BaseState`, `RepositoryHelper`, response models
- `lib/injection_container.dart` — GetIt stub

### `feature`

Generates a full feature module:

```
lib/features/<feature>/
  data/       datasources, models, repositories
  domain/     entities, params, repositories, usecases
  presentation/ blocs, screens, widgets
```

Interactive questionnaire (each step shows an example — press Enter to use it):

1. endpoint
2. REST method
3. query params JSON (optional)
4. request body JSON (optional)
5. base response JSON (`status`, `message`) — reused across features
6. response data JSON (one list item)
7. is paginated?
8. pagination JSON (`paginationData` by default)

Project defaults for base response and pagination are saved in `uncle_bob.yaml` and reused on the next feature unless you choose to change them.

### `feature --no-prompt`

```bash
uncle_bob feature organizations \
  --no-prompt \
  --endpoint /organizations \
  --method GET \
  --paginated \
  --params '{"search":"test"}' \
  --response-base '{"status":true,"message":"OK"}' \
  --response-data '[{"id":1,"name":"Acme"}]' \
  --pagination '{"total":129,"per_page":20,"current_page":1,"last_page":7}'
```

`--response` / `--response-file` still work and are auto-split into base/data/pagination.

## Config (`uncle_bob.yaml`)

```yaml
package_name: my_app
features_path: lib/features
core_path: lib/core
di_file: lib/injection_container.dart
last_base_response_example: |
  {"status": true, "message": "OK"}
last_pagination_example: |
  {"total": 129, "per_page": 20, "current_page": 1, "last_page": 7}
last_pagination_key: paginationData
```

## Generated app dependencies

`init` adds these when possible:

```yaml
dependencies:
  dartz: ^0.10.1
  dio: ^5.8.0
  equatable: ^2.0.7
  flutter_bloc: ^9.1.0
  get_it: ^8.0.3

dev_dependencies:
  bloc: ^9.0.0
```

Wire `initDependencies()` from `main.dart`, paste each `init<Feature>()` snippet, and expand entity/model fields from your data example (scaffold starts with `id` + `name`).

## Roadmap

- **v0.2** — `uncle_bob endpoint` per REST endpoint
- **v0.3** — OpenAPI / endpoint definitions in `uncle_bob.yaml`
- Optional VS Code extension wrapper

## Develop

```bash
git clone https://github.com/jawadabbasnia/uncle_bob.git
cd uncle_bob
dart pub get
dart test
dart analyze
dart pub publish --dry-run
dart run uncle_bob:uncle_bob --help
```

## Publish checklist

```bash
dart pub publish --dry-run   # must pass with no errors
dart pub publish             # when ready
```

## License

MIT — see [LICENSE](LICENSE).
