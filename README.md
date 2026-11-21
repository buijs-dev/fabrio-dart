# Fabrio Dart

The Dart and Flutter side of Fabrio, the reference implementation of the
[Rialto specification](https://github.com/buijs-dev/rialto-spec): a client generator for Rialto contracts, the
runtime the generated code uses, and widget kits. Its server side is
[fabrio-jvm](https://github.com/buijs-dev/fabrio-jvm); both are generated from the same Rialto contract and work
together without shared code.

**Status:** slice 0 of the way to 1.0.0, the foundation. Fabrio Dart is built again in slices: each slice brings one
profile of the specification through every layer, and each is green on its own. See [Status](#status).

## Packages

| Package | Platform | Contents |
|---|---|---|
| `fabrio_generator` | Dart (tool) | the client generator; in slice 0 its first stage, the contract frontend and the client IR ([README](packages/fabrio_generator/README.md)) |

The guide is in [docs/README.md](docs/README.md); the changes are in the [CHANGELOG](CHANGELOG.md).

## Status

| Slice | Profile | Fabrio Dart | State |
|---|---|---|---|
| 0 | Fundament: core, contract | the workspace; the contract frontend and the IR of the generator, at the level of the contract format | this slice |
| 1 | Domain and mapping | models, mapping | planned |
| 2 | REST and errors | the HTTP client, error handling | planned |
| 3 | Persistence | — | — |
| 4 | Query | lists and search | planned |
| 5 | Lifecycle | actions and their availability | planned |
| 6 | Auth | the session, access | planned |
| 7 | Events | live views | planned |
| 8 | Presentation | views, forms, navigation and the widget kits | planned |
| 9 | Versioning and compatibility | — | — |
| 10 | Ecosystem | the generator protocol (`serveProtocol`), the manifest | planned |

The runtime packages, the optional libraries and the example apps arrive with the slice that needs them.

## Building and testing

The generator reads a contract with `rialto_generator`, the generator library of
[rialto-dart](https://github.com/buijs-dev/rialto-dart). It is not published yet: the workspace takes it as a path
dependency, from a checkout at `../../rialto/rialto-dart`:

```text
<root>/
  fabrio/fabrio-dart/    this repository
  rialto/rialto-dart/    buijs-dev/rialto-dart, on the branch of the same slice
```

```sh
dart pub get
tool/ci.sh     # format, analyze, and the tests of every package
```

## License

Apache License 2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE).
