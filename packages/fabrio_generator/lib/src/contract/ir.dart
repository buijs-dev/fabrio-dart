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

/// The client IR: what the generator knows about a Rialto contract and its documents after reading them, before
/// rendering.
///
/// Slice 0 holds what the contract format itself says (contract K): the contract's name and the OpenAPI sources the
/// app calls. The profiles add their part one slice each: the models of each source (domain and mapping, slice 1), its
/// operations and the error model (rest and errors, slice 2), lists (query, slice 4), lifecycles (slice 5), the auth
/// client (slice 6), streams and event types (events, slice 7), and local operations and views (presentation,
/// slice 8).
library;

/// One OpenAPI source the app calls (`sources.<name>`, contract: Sources and references).
final class ApiIR {
  const ApiIR({required this.source, required this.suffix, required this.basePath});

  /// The name under `sources`, such as `api`.
  final String source;

  /// Appended to every generated type name; empty when the app calls one source.
  final String suffix;

  /// The path of the first server URL, such as `/v2`; empty without one.
  final String basePath;

  @override
  bool operator ==(Object other) =>
      other is ApiIR && other.source == source && other.suffix == suffix && other.basePath == basePath;

  @override
  int get hashCode => Object.hash(source, suffix, basePath);

  @override
  String toString() => 'ApiIR($source, suffix: "$suffix", basePath: "$basePath")';
}

/// Everything the renderers need of the contract.
final class ClientIR {
  const ClientIR({required this.name, required this.apis});

  /// `info.name` of the contract, such as `shipment`: names the API classes (`ShipmentApi`).
  final String name;

  /// The OpenAPI sources the app calls, in contract order.
  final List<ApiIR> apis;
}
