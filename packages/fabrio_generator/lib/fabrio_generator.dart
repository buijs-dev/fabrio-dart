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

/// The client generator of Fabrio. Slice 0 holds its first stage: a Rialto contract to the client IR
/// ([ContractFrontend], [ClientIR]), at the level of the contract format. The profiles add to the IR one slice each;
/// the planners, the renderers and the generator itself (with `rialto_generator`) follow in their slices.
library;

export 'src/contract/contract_frontend.dart';
export 'src/contract/ir.dart';
export 'src/problems.dart';
