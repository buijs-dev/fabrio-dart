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

import 'package:rialto_contract/rialto_contract.dart';

/// A problem the generator finds in a contract: one it cannot generate, or reports while generating.
final class Problem {
  const Problem(this.severity, this.message, this.location, {this.hint});

  final Severity severity;
  final String message;
  final Location location;
  final String? hint;

  @override
  String toString() {
    final hintLine = hint != null ? '\n  hint: $hint' : '';
    return '${severity.name} $location: $message$hintLine';
  }
}

/// Collects the problems of one generation run, located in the contract or in one of its documents.
///
/// In slice 10 the generator reports them through `rialto_generator`, as `RIALTO-G006`; until then they are a list
/// of their own, next to the diagnostics of `rialto_contract`.
final class Problems {
  /// Pointers into the contract are located in [contract], the contract document.
  Problems(LocatedDocument contract, Sources sources) : this.at(contract.locate, sources);

  /// Pointers into the contract are located by [contractAt]: also for a contract that arrives as JSON, without its
  /// document.
  Problems.at(Location Function(String pointer) contractAt, this.sources) : _contractAt = contractAt;

  final Sources sources;
  final Location Function(String pointer) _contractAt;
  final _items = <Problem>[];

  List<Problem> get all => List.unmodifiable(_items);

  bool get hasErrors => _items.any((it) => it.severity == Severity.error);

  /// [source] null: [pointer] is in the contract; else in that source's document.
  void error(String message, {String? source, required String pointer, String? hint}) =>
      _items.add(Problem(Severity.error, message, _locate(source, pointer), hint: hint));

  void warning(String message, {String? source, required String pointer, String? hint}) =>
      _items.add(Problem(Severity.warning, message, _locate(source, pointer), hint: hint));

  Location _locate(String? source, String pointer) {
    if (source == null) return _contractAt(pointer);
    final loaded = sources.loaded[source];
    return loaded is DocumentSource
        ? loaded.document.locate(pointer)
        : Location(loaded?.file ?? source, pointer: pointer);
  }
}
