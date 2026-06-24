# Example

This folder documents how to use `uncle_bob` in a Flutter app.

## 1. Install the CLI

```bash
dart pub global activate uncle_bob
```

## 2. Bootstrap a Flutter project

```bash
cd my_flutter_app
uncle_bob init
uncle_bob feature settings
```

## 3. Wire dependency injection

Copy the printed `initSettings()` snippet into `lib/injection_container.dart` and call it from `initDependencies()`.

## 4. Use the generated screen

Provide the generated bloc via `BlocProvider` and navigate to the generated screen.

See the [package README](../README.md) for full command reference.
