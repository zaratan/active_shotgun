# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.3] - 2020-12-16
### Added
- First version of AR complient queries. Supports:
  - find
  - first(number)
  - find_by
  - all
  - where => Partial support. Hash only.
  - orders
  - limit
  - offset
  - select
  - pluck
- Behave as a Query as long as possible. Behave like an Array as soon as you look at the data.
### Missing
- multi-entity, entity
- count, extra methods

## [0.0.2.1] - 2020-12-16
### Changed
- Not everything is in one big file now

## [0.0.2] - 2020-12-16
### Added
- save, create, update, find, delete, revive (and friends)
- Validations support
- Callbacks support
- AM::Dirty and many helpers
### Missing
- Query interface (where, find_by, first, all, order, offset)
- Support Entity and Multi-Entity

## [0.0.1] - 2020-12-16
### Added
- Gem init

[Unreleased]: https://github.com/zaratan/active_shotgun/compare/v0.0.3...HEAD
[0.0.3]: https://github.com/zaratan/active_shotgun/releases/tag/v0.0.3
[0.0.2.1]: https://github.com/zaratan/active_shotgun/releases/tag/v0.0.2.1
[0.0.2]: https://github.com/zaratan/active_shotgun/releases/tag/v0.0.2
[0.0.1]: https://github.com/zaratan/active_shotgun/releases/tag/v0.0.1
