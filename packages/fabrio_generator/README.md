# fabrio_generator

The client generator of Fabrio: in the end, the Dart client and Flutter views of a
[Rialto contract](https://github.com/buijs-dev/rialto-spec), on the runtime packages of Fabrio.

**Slice 0** holds its first stage: the contract frontend, which reads a validated contract and the documents of its
sources into the client IR. It reads what the contract format itself says; the sections of the profiles are read by
the slice of each profile.

## Use

```dart
import 'package:fabrio_generator/fabrio_generator.dart';

final (:ir, :diagnostics, :problems) = ContractFrontend.readFile('shipment.rialto.yaml', options: {'sources': 'api'});
```

`readFile` validates the contract with `rialto_contract` first; without a valid contract there is no IR, only the
diagnostics. A contract that arrives as JSON reads with `ContractFrontend(Contract(json), sources, Problems.at(…))`.

| Option | Meaning | Default |
|---|---|---|
| `sources` | the OpenAPI sources the app calls, comma-separated | every OpenAPI source that is not deprecated |
| `<source>.suffix` | appended to the type names of a source | required with several sources |
| `<source>.basePath` | the path before the operation paths | the path of the source's first server |

Options are generator configuration, outside the contract (K1.6).

## What is in slice 0, and what follows

`lib/src/`:

- `contract/ir.dart`: `ClientIR`, the contract's name and its APIs, and `ApiIR`, one OpenAPI source;
- `contract/contract_frontend.dart`: the contract to the IR;
- `problems.dart`: what the generator reports, located in the contract or in one of its documents.

The cut follows the slices: the contract format in slice 0, the meaning of each profile in its own slice.

| Slice | Adds to the frontend and the IR |
|---|---|
| 1 | the models of each source through `mappings` and the contract types (the OpenAPI reader) |
| 2 | the operations with a REST binding, their parameters and security, and the error model |
| 4 | lists: fields, filter and sort encodings, pagination, counts |
| 5 | lifecycles, preconditions, idempotency and batches |
| 6 | the auth client of the app (the option `clients`) |
| 7 | streams and event types |
| 8 | local operations; then the view planner and the renderers |
| 10 | the generator itself on `rialto_generator`: the manifest, `serveProtocol`, and problems as `RIALTO-G006` |

## Tests

```sh
dart test
```
