// Copyright (c) 2021 - 2026 Buijs Software
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
// the License. You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

import 'package:fabrio_generator/fabrio_generator.dart';
import 'package:rialto_contract/rialto_contract.dart';
import 'package:test/test.dart';

const fixtures = 'test/fixtures';
const sourcesContract = '$fixtures/sources/sources.rialto.yaml';

/// Reads [file] as a generation run would, with [options].
({ClientIR? ir, List<Diagnostic> diagnostics, List<Problem> problems}) read(
  String file, [
  Map<String, String> options = const {},
]) => ContractFrontend.readFile(file, options: options);

void main() {
  test('the name of the contract, and the current OpenAPI source only', () {
    final (:ir, :diagnostics, :problems) = read(sourcesContract);
    expect(diagnostics, isEmpty);
    expect(problems, isEmpty);
    expect(ir!.name, 'shipment');
    // apiV1 is deprecated, and events is no OpenAPI source.
    expect(ir.apis, [const ApiIR(source: 'api', suffix: '', basePath: '/v2')]);
  });

  test('a contract without sources is a client of no API', () {
    final (:ir, :diagnostics, :problems) = read('$fixtures/minimal/minimal.rialto.yaml');
    expect(diagnostics, isEmpty);
    expect(problems, isEmpty);
    expect(ir!.name, 'minimal');
    expect(ir.apis, isEmpty);
  });

  test('a contract that does not validate gives no IR, and its diagnostics (K1.7)', () {
    final (:ir, :diagnostics, :problems) = read('$fixtures/invalid/invalid.rialto.yaml');
    expect(ir, isNull);
    expect(diagnostics.map((d) => d.id), contains('RIALTO-K002'));
    expect(problems, isEmpty);
  });

  group('options (K1.6)', () {
    test('sources selects the OpenAPI sources the app calls, deprecated ones too', () {
      final (:ir, :problems, diagnostics: _) = read(sourcesContract, const {'sources': 'apiV1'});
      expect(problems, isEmpty);
      expect(ir!.apis, [const ApiIR(source: 'apiV1', suffix: '', basePath: '/v1')]);
    });

    test('several sources need a suffix each', () {
      final missing = read(sourcesContract, const {'sources': 'api, apiV1'});
      expect(missing.ir!.apis, isEmpty);
      expect(missing.problems.map((p) => p.message), everyElement(contains('needs a suffix')));
      expect(missing.problems.map((p) => p.hint), ['set the option api.suffix, for example api.suffix=Api', anything]);
      expect(missing.problems.map((p) => p.location.pointer), ['/sources/api', '/sources/apiV1']);
      expect(missing.problems.first.location.line, 5);

      final both = read(sourcesContract, const {'sources': 'api,apiV1', 'api.suffix': 'V2', 'apiV1.suffix': 'V1'});
      expect(both.problems, isEmpty);
      expect(both.ir!.apis, [
        const ApiIR(source: 'api', suffix: 'V2', basePath: '/v2'),
        const ApiIR(source: 'apiV1', suffix: 'V1', basePath: '/v1'),
      ]);
    });

    test('basePath replaces the path of the first server', () {
      final (:ir, :problems, diagnostics: _) = read(sourcesContract, const {'api.basePath': ''});
      expect(problems, isEmpty);
      expect(ir!.apis.single.basePath, '');
    });

    test('a source that is unknown or no OpenAPI source is reported', () {
      final (:ir, :problems, diagnostics: _) = read(sourcesContract, const {'sources': 'nope,events'});
      expect(ir!.apis, isEmpty);
      expect(problems.map((p) => p.message), [contains('"nope"'), contains('"events"')]);
      expect(problems.every((p) => p.severity == Severity.error), isTrue);
    });
  });

  test('a contract that arrives as JSON reads the same, located by the caller', () {
    final document = LocatedDocument.read('$fixtures/sources/openapi-v1.yaml');
    final contract = Contract({
      'rialto': '1.0.0',
      'info': {'name': 'json', 'version': '1.0.0'},
      'sources': {
        'api': {'kind': 'openapi', 'path': 'openapi.yaml', 'version': '1.0.0', 'status': 'current'},
        'gone': {'kind': 'openapi', 'path': 'gone.yaml', 'version': '1.0.0', 'status': 'current'},
      },
    });
    final sources = Sources({'api': DocumentSource('api', document.file, document)});
    final problems = Problems.at((pointer) => Location('contract.json', pointer: pointer), sources);
    final ir = ContractFrontend(contract, sources, problems, options: const {'sources': 'gone'}).read();
    expect(ir.name, 'json');
    expect(ir.apis, isEmpty);
    expect(problems.all.single.message, 'the OpenAPI source "gone" could not be read');
    expect(problems.all.single.location.toString(), 'contract.json #/sources/gone');

    final api = ContractFrontend(
      contract,
      sources,
      Problems.at(Location.new, sources),
      options: const {'sources': 'api'},
    ).read();
    expect(api.apis, [const ApiIR(source: 'api', suffix: '', basePath: '/v1')]);
  });
}
