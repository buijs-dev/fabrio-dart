# fabrio_generator

The client generator of Fabrio: in the end, the Dart client and Flutter views of a
[Rialto contract](https://github.com/buijs-dev/rialto-spec), on the runtime packages of Fabrio.

**Slice 0** holds its first stage: the contract frontend, which reads a contract and the documents of its sources
into the client IR. It reads what the contract format itself says; the sections of the profiles are read by the
slice of each profile.

The generator does not validate. The `rialto` command line of
[rialto-jvm](https://github.com/buijs-dev/rialto-jvm) validates a contract and bundles it, and hands a generator the
result. The frontend reads it with `rialto_generator`, the generator library of
[rialto-dart](https://github.com/buijs-dev/rialto-dart).

## Use

```dart
import 'package:fabrio_generator/fabrio_generator.dart';
import 'package:rialto_generator/rialto_generator.dart';

void main() {
  final document = LocatedDocument.read('build/shipment.bundled.yaml');
  final openApi = LocatedDocument.read('openapi.yaml');
  final sources = Sources({'api': DocumentSource('api', openApi.file, openApi)});
  final problems = Problems(document, sources);
  final ir = ContractFrontend(Contract(asMap(document.root)), sources, problems, options: {'sources': 'api'}).read();
  print('${ir.name} calls ${ir.apis.map((api) => api.source).join(', ')}');
  problems.all.forEach(print);
}
```

`problems.all` holds what the frontend reports, located in the contract or in a source document. A contract that
arrives as JSON, without its document, takes `Problems.at(…)`, which locates a pointer by the caller.

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
