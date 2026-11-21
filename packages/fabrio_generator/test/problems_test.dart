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
import 'package:rialto_generator/rialto_generator.dart';
import 'package:test/test.dart';

const fixtures = 'test/fixtures/sources';

void main() {
  final contract = LocatedDocument.read('$fixtures/sources.rialto.yaml');
  final openApi = LocatedDocument.read('$fixtures/openapi-v1.yaml');
  final sources = Sources({'apiV1': DocumentSource('apiV1', openApi.file, openApi)});

  Problems problems() => Problems(contract, sources);

  group('locating', () {
    test('a pointer into the contract, at its line in the contract document', () {
      final all = problems()..error('broken', pointer: '/sources/api');
      expect(all.all.single.location.file, contract.file);
      expect(all.all.single.location.line, 5);
      expect(all.all.single.location.pointer, '/sources/api');
    });

    test('a pointer into a loaded OpenAPI document, at its line in that document', () {
      final all = problems()..error('no path', source: 'apiV1', pointer: '/servers/0/url');
      expect(all.all.single.location.file, openApi.file);
      expect(all.all.single.location.line, 4);
      expect(all.all.single.location.pointer, '/servers/0/url');
    });

    test('a source that is not loaded, by its name', () {
      final all = problems()..error('unread', source: 'events', pointer: '/channels');
      expect('${all.all.single.location}', 'events #/channels');
    });

    test('by the caller, for a contract without its document', () {
      final all = Problems.at((pointer) => Location('contract.json', line: 1, pointer: pointer), sources)
        ..error('broken', pointer: '/info');
      expect('${all.all.single.location}', 'contract.json:1:1 #/info');
    });
  });

  test('errors fail the run, warnings do not', () {
    final all = problems();
    expect(all.hasErrors, isFalse);
    all.warning('deprecated', pointer: '/sources/apiV1');
    expect(all.hasErrors, isFalse);
    all.error('broken', pointer: '/sources/api');
    expect(all.hasErrors, isTrue);
    expect(all.all.map((p) => p.severity), [Severity.warning, Severity.error]);
  });

  test('the list of problems cannot be changed from outside', () {
    final all = problems()..error('broken', pointer: '');
    expect(() => all.all.clear(), throwsUnsupportedError);
  });

  test('a problem reads as its severity, location and message, and its hint on a line of its own', () {
    final all = problems()
      ..error('needs a suffix', pointer: '/sources/api', hint: 'set the option api.suffix')
      ..warning('no channel', source: 'events', pointer: '/channels');
    expect(
      '${all.all.first}',
      'error sources.rialto.yaml:5:3 #/sources/api: needs a suffix\n  hint: set the option api.suffix',
    );
    expect('${all.all.last}', 'warning events #/channels: no channel');
    expect(all.all.first.hint, 'set the option api.suffix');
    expect(all.all.last.hint, isNull);
  });
}
