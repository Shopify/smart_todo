# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2019-11-25
### Fixed
- Fixed crash with badly formated TODO(on:) (i.e. `TODO(on: 'blabla'))

### Added
- Added the `on: gem_bump` event which will remind you when a gem inside your
  Gemfile.lock snapshot gets updated to a specific version.

  ```ruby
  # TODO(on: gem_bump('rails', '6.1'), to: '...')
  ```

## [1.1.0] - 2019-09-06
### Fixed
- Fixed the SmartTodo cop to add an offense in case a SmartTodo has a wrong event.
  ```ruby
  # Bad
  #
  # TODO(on '2019-08-08')
  ```

### Added
- SmartTodo will now use the fallback channel in case a todo has a channel
  assignee that doesn't exist.
- Added a new `Output` dispatcher which will just output the expired event.
  By default SmartTodo will now output expired todo in the terminal instead
  of not running at all.

  Users should now pass a `--dispatcher` to the CLI to let SmartTodo through
  which dispatcher the message should be send.

  ```sh
    bin/smart_todo --dispatcher 'slack'
  ```

  For backward compatibility reasons, the dispacher used will be Slack, in
  case you have the `ENABLE_SMART_TODO` environment set. This will be removed
  in the next major version.

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
