# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.2] - 2019-08-09
### Fixed
- Fixed the SmartTodo cop to add an offense in case a SmartTodo has no assignee.
  ```ruby
  # Bad
  #
  # TODO(on: date('2019-08-08'))
  ```

## [1.0.1] - 2019-08-06
### Fixed
- Fixed `issue_close` event making a call to the `pulls/` GH endpoint instead of the `issues/` one

## [1.0.0] - 2019-07-19
### Added
- Initial Release
