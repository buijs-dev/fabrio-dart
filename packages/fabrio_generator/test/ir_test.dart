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
import 'package:test/test.dart';

void main() {
  group('ApiIR', () {
    const api = ApiIR(source: 'api', suffix: 'V2', basePath: '/v2');

    test('is a value: equal, with the same hash, when source, suffix and base path are', () {
      const same = ApiIR(source: 'api', suffix: 'V2', basePath: '/v2');
      expect(api, same);
      expect(api.hashCode, same.hashCode);
      expect(<ApiIR>{}..addAll([api, same]), hasLength(1));
    });

    test('differs in each of its fields', () {
      expect(api, isNot(const ApiIR(source: 'apiV1', suffix: 'V2', basePath: '/v2')));
      expect(api, isNot(const ApiIR(source: 'api', suffix: '', basePath: '/v2')));
      expect(api, isNot(const ApiIR(source: 'api', suffix: 'V2', basePath: '')));
      expect(api, isNot('api'));
    });

    test('shows its fields, so that a failing expectation says which one differs', () {
      expect('$api', 'ApiIR(api, suffix: "V2", basePath: "/v2")');
      expect('${const ApiIR(source: 'api', suffix: '', basePath: '')}', 'ApiIR(api, suffix: "", basePath: "")');
    });
  });

  test('ClientIR holds the name and the APIs in their order', () {
    const apis = [ApiIR(source: 'b', suffix: 'B', basePath: ''), ApiIR(source: 'a', suffix: 'A', basePath: '/a')];
    const ir = ClientIR(name: 'shipment', apis: apis);
    expect(ir.name, 'shipment');
    expect(ir.apis.map((api) => api.source), ['b', 'a']);
  });
}
