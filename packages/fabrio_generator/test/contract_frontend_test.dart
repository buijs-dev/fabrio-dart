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

import 'dart:io';

import 'package:fabrio_generator/fabrio_generator.dart';
import 'package:rialto_generator/rialto_generator.dart';
import 'package:test/test.dart';

const fixtures = 'test/fixtures';
const sourcesContract = '$fixtures/sources/sources.rialto.yaml';

/// Reads the bundled contract [file] and the documents of its sources next to it, as the `rialto` command line hands
/// them to a generator, with [options].
({ClientIR ir, List<Problem> problems}) read(String file, [Map<String, String> options = const {}]) {
  final document = LocatedDocument.read(file);
  final contract = Contract(asMap(document.root));
  final directory = File(file).parent.path;
  final sources = Sources({
    for (final MapEntry(key: name, :value) in contract.sources.entries)
      name: DocumentSource(
        name,
        '$directory/${asMap(value)['path']}',
        LocatedDocument.read('$directory/${asMap(value)['path']}'),
      ),
  });
  final problems = Problems(document, sources);
  final ir = ContractFrontend(contract, sources, problems, options: options).read();
  return (ir: ir, problems: problems.all);
}

void main() {
  test('the name of the contract, and the current OpenAPI source only', () {
    final (:ir, :problems) = read(sourcesContract);
    expect(problems, isEmpty);
    expect(ir.name, 'shipment');
    // apiV1 is deprecated, and events is no OpenAPI source.
    expect(ir.apis, [const ApiIR(source: 'api', suffix: '', basePath: '/v2')]);
  });

  test('a contract without sources is a client of no API', () {
    final (:ir, :problems) = read('$fixtures/minimal/minimal.rialto.yaml');
    expect(problems, isEmpty);
    expect(ir.name, 'minimal');
    expect(ir.apis, isEmpty);
  });

  group('options (K1.6)', () {
    test('sources selects the OpenAPI sources the app calls, deprecated ones too', () {
      final (:ir, :problems) = read(sourcesContract, const {'sources': 'apiV1'});
      expect(problems, isEmpty);
      expect(ir.apis, [const ApiIR(source: 'apiV1', suffix: '', basePath: '/v1')]);
    });

    test('several sources need a suffix each', () {
      final missing = read(sourcesContract, const {'sources': 'api, apiV1'});
      expect(missing.ir.apis, isEmpty);
      expect(missing.problems.map((p) => p.message), everyElement(contains('needs a suffix')));
      expect(missing.problems.map((p) => p.hint), ['set the option api.suffix, for example api.suffix=Api', anything]);
      expect(missing.problems.map((p) => p.location.pointer), ['/sources/api', '/sources/apiV1']);
      expect(missing.problems.first.location.line, 5);

      final both = read(sourcesContract, const {'sources': 'api,apiV1', 'api.suffix': 'V2', 'apiV1.suffix': 'V1'});
      expect(both.problems, isEmpty);
      expect(both.ir.apis, [
        const ApiIR(source: 'api', suffix: 'V2', basePath: '/v2'),
        const ApiIR(source: 'apiV1', suffix: 'V1', basePath: '/v1'),
      ]);
    });

    test('basePath replaces the path of the first server', () {
      final (:ir, :problems) = read(sourcesContract, const {'api.basePath': ''});
      expect(problems, isEmpty);
      expect(ir.apis.single.basePath, '');
    });

    test('sources keeps the order of the contract, and calls a source named twice once', () {
      final (:ir, :problems) = read(sourcesContract, const {
        'sources': 'apiV1, api ,apiV1',
        'api.suffix': 'V2',
        'apiV1.suffix': 'V1',
      });
      expect(problems, isEmpty);
      expect(ir.apis.map((api) => api.source), ['api', 'apiV1']);

      final once = read(sourcesContract, const {'sources': 'api,api'});
      expect(once.problems, isEmpty);
      expect(once.ir.apis, [const ApiIR(source: 'api', suffix: '', basePath: '/v2')]);
    });

    test('sources without a name calls no source', () {
      for (final option in ['', ' , ']) {
        final (:ir, :problems) = read(sourcesContract, {'sources': option});
        expect(problems, isEmpty);
        expect(ir.apis, isEmpty);
      }
    });

    test('a single source takes a suffix too', () {
      final (:ir, :problems) = read(sourcesContract, const {'api.suffix': 'Shipment'});
      expect(problems, isEmpty);
      expect(ir.apis.single.suffix, 'Shipment');
    });

    test('options the frontend does not read are left to the other stages, also those of a source not called', () {
      final (:ir, :problems) = read(sourcesContract, const {
        'package': 'shipment_client',
        'apiV1.suffix': 'V1',
        'apiV1.basePath': '/old',
        'events.suffix': 'Events',
      });
      expect(problems, isEmpty);
      expect(ir.apis, [const ApiIR(source: 'api', suffix: '', basePath: '/v2')]);
    });

    test('a source that is unknown or no OpenAPI source is reported', () {
      final (:ir, :problems) = read(sourcesContract, const {'sources': 'nope,events'});
      expect(ir.apis, isEmpty);
      expect(problems.map((p) => p.message), [contains('"nope"'), contains('"events"')]);
      expect(problems.every((p) => p.severity == Severity.error), isTrue);
      expect(problems.map((p) => p.location.pointer), everyElement('/sources'));
      expect(problems.first.location.line, 4);
    });

    test('a known source is still called next to an unknown one', () {
      final (:ir, :problems) = read(sourcesContract, const {'sources': 'api,nope'});
      expect(problems.single.message, contains('"nope"'));
      expect(ir.apis.map((api) => api.source), ['api']);
    });
  });

  group('the base path, from the first server URL', () {
    String basePath(String servers) {
      final document = LocatedDocument.parse('openapi: 3.1.0\n$servers\npaths: {}\n', 'openapi.yaml');
      final sources = Sources({'api': DocumentSource('api', document.file, document)});
      final contract = Contract({
        'rialto': '1.0.0',
        'info': {'name': 'json', 'version': '1.0.0'},
        'sources': {
          'api': {'kind': 'openapi', 'path': 'openapi.yaml', 'version': '1.0.0', 'status': 'current'},
        },
      });
      final problems = Problems.at(Location.new, sources);
      final ir = ContractFrontend(contract, sources, problems).read();
      expect(problems.all, isEmpty);
      return ir.apis.single.basePath;
    }

    test('is the path of that URL, without a trailing slash', () {
      expect(basePath('servers: [{url: "https://a.invalid/v2/"}, {url: "https://b.invalid/v3"}]'), '/v2');
      expect(basePath('servers: [{url: "https://a.invalid/api/v2"}]'), '/api/v2');
      expect(basePath('servers: [{url: /v4}]'), '/v4');
    });

    test('is empty for a URL without a path, without servers, or for a server without a URL', () {
      expect(basePath('servers: [{url: "https://a.invalid"}]'), '');
      expect(basePath('servers: [{url: "https://a.invalid/"}]'), '');
      expect(basePath('servers: []'), '');
      expect(basePath('servers: [{description: none}]'), '');
      expect(basePath('info: {title: no servers, version: 1.0.0}'), '');
    });
  });

  test('a source document that is no mapping is reported, not read', () {
    final document = LocatedDocument.parse('- not an OpenAPI document\n', 'list.yaml');
    final sources = Sources({'api': DocumentSource('api', document.file, document)});
    final contract = Contract({
      'rialto': '1.0.0',
      'info': {'version': '1.0.0'},
      'sources': {
        'api': {'kind': 'openapi', 'path': 'list.yaml', 'version': '1.0.0', 'status': 'current'},
      },
    });
    final problems = Problems.at(Location.new, sources);
    final ir = ContractFrontend(contract, sources, problems).read();
    // Without info.name, which only a contract that skipped validation lacks, the client is named app.
    expect(ir.name, 'app');
    expect(ir.apis, isEmpty);
    expect(problems.hasErrors, isTrue);
    expect(problems.all.single.message, 'the OpenAPI source "api" could not be read');
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
