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

import 'package:rialto_generator/rialto_generator.dart';

import '../problems.dart';
import 'ir.dart';

/// Reads what a client needs from a Rialto contract and the documents of its sources.
///
/// It does not validate: the `rialto` command line validates a contract and bundles it, and hands a generator the
/// result.
///
/// Slice 0 reads what the contract format itself says: the name of the contract and the OpenAPI sources the app
/// calls, each with its suffix and base path. The sections of the profiles are left alone (K1.4) until the slice of
/// each profile reads them; see [ClientIR].
///
/// Options, generator configuration outside the contract (K1.6):
/// - `sources`: the OpenAPI sources the app calls, comma-separated; default every source that is not deprecated;
/// - `<source>.suffix`: appended to its type names; required when the app calls several sources;
/// - `<source>.basePath`: the path before the operation paths; default the path of the first server URL.
final class ContractFrontend {
  ContractFrontend(this.contract, this.sources, this.problems, {this.options = const {}});

  /// A contract that is validated and bundled.
  final Contract contract;
  final Sources sources;
  final Problems problems;
  final Map<String, String> options;

  ClientIR read() {
    final selected = _selectedSources();
    final apis = <ApiIR>[];
    for (final name in selected) {
      if (_api(name, selected.length) case final api?) {
        apis.add(api);
      }
    }
    return ClientIR(name: '${contract.info['name'] ?? 'app'}', apis: apis);
  }

  // Sources

  List<String> _selectedSources() {
    final openApi = {
      for (final MapEntry(:key, :value) in contract.sources.entries)
        if (asMap(value)['kind'] == 'openapi') key: asMap(value),
    };
    final option = options['sources'];
    if (option == null) {
      return [
        for (final MapEntry(:key, :value) in openApi.entries)
          if (value['status'] != 'deprecated') key,
      ];
    }
    final names = {
      for (final name in option.split(','))
        if (name.trim().isNotEmpty) name.trim(),
    };
    for (final name in names) {
      if (!openApi.containsKey(name)) {
        problems.error(
          'the option sources names "$name", which is not an OpenAPI source of the contract',
          pointer: '/sources',
        );
      }
    }
    // In contract order, as the IR has them, whatever the order of the option; a name given twice is called once.
    return [
      for (final name in openApi.keys)
        if (names.contains(name)) name,
    ];
  }

  ApiIR? _api(String source, int count) {
    final loaded = sources.loaded[source];
    final root = loaded is DocumentSource ? loaded.document.root : null;
    if (root is! Map<String, Object?>) {
      problems.error('the OpenAPI source "$source" could not be read', pointer: '/sources/$source');
      return null;
    }
    if (count > 1 && !options.containsKey('$source.suffix')) {
      problems.error(
        'the app calls several OpenAPI sources, so "$source" needs a suffix for its type names',
        pointer: '/sources/$source',
        hint: 'set the option $source.suffix, for example $source.suffix=${_pascal(source)}',
      );
      return null;
    }
    return ApiIR(
      source: source,
      suffix: options['$source.suffix'] ?? '',
      basePath: options['$source.basePath'] ?? _basePath(root),
    );
  }

  static String _basePath(Map<String, Object?> root) {
    final servers = root['servers'];
    if (servers is! List || servers.isEmpty) {
      return '';
    }
    final url = Uri.tryParse('${asMap(servers.first)['url'] ?? ''}');
    final path = url?.path ?? '';
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  static String _pascal(String name) => name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}
