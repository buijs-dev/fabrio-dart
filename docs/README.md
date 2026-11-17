# Fabrio Dart guide

How the parts fit together and where each part lives. The package table and the status per slice are in the
[README](../README.md); the changes are in the [CHANGELOG](../CHANGELOG.md).

## How the pieces fit

```
Rialto contract ──► rialto_contract (rialto-dart): validated contract and its source documents
                        │
                        ▼
                  fabrio_generator: contract frontend ──► client IR
```

In slice 0 the generator ends at the IR. The planners and renderers that turn the IR into code, the runtime that
code uses, and the widget kits that draw its views follow one slice per profile.

## Where to find what

Paths are relative to `packages/`. The *Spec* column names the requirements of the
[Rialto specification](https://github.com/buijs-dev/rialto-spec) that the code implements.

| Concept | Package and file | Spec | Worked example |
|---|---|---|---|
| The contract to the client IR: the contract's name, the OpenAPI sources the app calls, the options | `fabrio_generator/lib/src/contract/contract_frontend.dart` | contract K1.4, K1.6, K1.7 | `fabrio_generator/test/contract_frontend_test.dart` |
| The client IR (`ClientIR`, `ApiIR`) | `fabrio_generator/lib/src/contract/ir.dart` | contract | `fabrio_generator/test/contract_frontend_test.dart` |
| Problems of a generation run, located in the contract or a source | `fabrio_generator/lib/src/problems.dart` | — | `fabrio_generator/test/contract_frontend_test.dart` |

## Tools and checks

Run everything from the workspace root.

| Command | What it does |
|---|---|
| `dart pub get` | resolves the workspace, with rialto-dart from `../../rialto/rialto-dart` |
| `tool/ci.sh` | all CI checks, in order: format, analyze, every package's tests |
