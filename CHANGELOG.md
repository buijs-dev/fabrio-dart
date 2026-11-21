# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Towards 1.0.0, built in slices. This section holds slice 0, the foundation.

### Added

- The workspace: `fabrio_generator`, the recommended lints with strict casts, inference and raw types, braces around
  the body of every if statement and loop, analysis with `--fatal-infos`, and `tool/ci.sh` (format, analyze, tests). The Rialto generator library comes from a checkout of
  rialto-dart next to this repository, as a path dependency.
- `fabrio_generator`, its first stage at the level of the contract format:
  - `ContractFrontend`: a contract that the `rialto` command line has validated and bundled, read with
    `rialto_generator`, to the client IR;
  - `ClientIR` and `ApiIR`: the name of the contract, and the OpenAPI sources the app calls, each with its suffix
    and base path; the options `sources`, `<source>.suffix` and `<source>.basePath`;
  - `Problems`: what the generator reports, located in the contract or in a source document.
- CI: format, analysis and tests on every pull request and on pushes to `develop` and `main`, against rialto-dart at
  the branch of the same name, or else `develop`.
