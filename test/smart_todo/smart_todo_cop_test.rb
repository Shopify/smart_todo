# frozen_string_literal: true

require "test_helper"
require "rubocop"
require "rubocop/rspec/expect_offense"
require "smart_todo_cop"

module SmartTodo
  class SmartTodoCopTest < Minitest::Test
    def test_add_offense_when_todo_is_a_regular_todo
      expect_offense(<<~RUBY)
        # TODO: Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_is_a_smart_todo_but_malformated
      expect_offense(<<~RUBY)
        # TODO(date('2019-08-04'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_an_invalid_event
      expect_offense(<<~RUBY)
        # TODO(on: '2019-08-04', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:on` event format: "2019-08-04". For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_an_event_but_no_assignee
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'))
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_event_is_not_a_valid_method
      expect_offense(<<~RUBY)
        # TODO(on: data('2019-08-04'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid event method(s): data. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_assignee_is_not_a_string
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: #foo)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid event assignee. This method only accepts strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_assignee_is_an_array
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: ['#foo', '#bar'])
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid event assignee. This method only accepts strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_invalid_date_format
      expect_offense(<<~RUBY)
        # TODO(on: date('invalid-date'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid date format: invalid-date. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_invalid_month
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-13-01'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid date format: 2024-13-01. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_invalid_day
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-04-31'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid date format: 2024-04-31. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_invalid_day_in_february
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-02-30'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid date format: 2024-02-30. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_invalid_day_in_non_leap_year
      expect_offense(<<~RUBY)
        # TODO(on: date('2023-02-29'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid date format: 2023-02-29. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_date_is_not_a_string
      expect_offense(<<~RUBY)
        # TODO(on: date(2023-10-01), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:on` event format: date(2023-10-01). For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_date_is_nil
      expect_offense(<<~RUBY)
        # TODO(on: date(nil), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:on` event format: date(nil). For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_assignee_is_a_list_of_strings
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#foo', to: '#bar', owner: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_is_a_smart_todo
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_comment_is_not_a_todo
      expect_no_offense(<<~RUBY)
        # @return [Void]
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_question_mark
      expect_offense(<<~RUBY)
        # TODO?
        ^^^^^^^ #{expected_message}
      RUBY
    end

    def test_add_offense_when_todo_has_missing_issue_close_arguments
      expect_offense(<<~RUBY)
        # TODO(on: issue_close('shopify'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid issue_close event: Expected 3 arguments (organization, repo, issue_number), got 1. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_too_many_issue_close_arguments
      expect_offense(<<~RUBY)
        # TODO(on: issue_close('shopify', 'repo', '123', 'extra'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid issue_close event: Expected 3 arguments (organization, repo, issue_number), got 4. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_issue_close_arguments
      expect_offense(<<~RUBY)
        # TODO(on: issue_close(123, 456, 789), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid issue_close event: Arguments must be strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_missing_pull_request_close_arguments
      expect_offense(<<~RUBY)
        # TODO(on: pull_request_close('shopify'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid pull_request_close event: Expected 3 arguments (organization, repo, pr_number), got 1. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_too_many_pull_request_close_arguments
      expect_offense(<<~RUBY)
        # TODO(on: pull_request_close('shopify', 'repo', '123', 'extra'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid pull_request_close event: Expected 3 arguments (organization, repo, pr_number), got 4. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_pull_request_close_arguments
      expect_offense(<<~RUBY)
        # TODO(on: pull_request_close(123, 456, 789), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid pull_request_close event: Arguments must be strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_missing_gem_release_arguments
      expect_offense(<<~RUBY)
        # TODO(on: gem_release(), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid gem_release event: Expected at least 1 argument (gem_name), got 0. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_gem_release_name
      expect_offense(<<~RUBY)
        # TODO(on: gem_release(123), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid gem_release event: First argument (gem_name) must be a string. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_gem_release_requirements
      expect_offense(<<~RUBY)
        # TODO(on: gem_release('rails', 123), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid gem_release event: Version requirements must be strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_valid_gem_release
      expect_no_offense(<<~RUBY)
        # TODO(on: gem_release('rails'), to: 'john@example.com')
        def hello
        end

        # TODO(on: gem_release('rails', '>= 6.0'), to: 'john@example.com')
        def hello
        end

        # TODO(on: gem_release('rails', '>= 6.0', '< 7.0'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_missing_gem_bump_arguments
      expect_offense(<<~RUBY)
        # TODO(on: gem_bump(), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid gem_bump event: Expected at least 1 argument (gem_name), got 0. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_gem_bump_name
      expect_offense(<<~RUBY)
        # TODO(on: gem_bump(123), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid gem_bump event: First argument (gem_name) must be a string. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_gem_bump_requirements
      expect_offense(<<~RUBY)
        # TODO(on: gem_bump('rails', 123), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid gem_bump event: Version requirements must be strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_valid_gem_bump
      expect_no_offense(<<~RUBY)
        # TODO(on: gem_bump('rails'), to: 'john@example.com')
        def hello
        end

        # TODO(on: gem_bump('rails', '>= 6.0'), to: 'john@example.com')
        def hello
        end

        # TODO(on: gem_bump('rails', '>= 6.0', '< 7.0'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_missing_ruby_version_arguments
      expect_offense(<<~RUBY)
        # TODO(on: ruby_version(), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid ruby_version event: Expected at least 1 argument (version requirement), got 0. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_non_string_ruby_version_requirements
      expect_offense(<<~RUBY)
        # TODO(on: ruby_version(123), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid ruby_version event: Version requirements must be strings. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_valid_ruby_version
      expect_no_offense(<<~RUBY)
        # TODO(on: ruby_version('>= 2.5'), to: 'john@example.com')
        def hello
        end

        # TODO(on: ruby_version('>= 2.5', '< 3.0'), to: 'john@example.com')
        def hello
        end

        # TODO(on: ruby_version('~> 2.5'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_add_offense_when_fixme_is_a_regular_fixme
      expect_offense(<<~RUBY)
        # FIXME: Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_optimize_is_a_regular_optimize
      expect_offense(<<~RUBY)
        # OPTIMIZE: Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_fixme_is_a_smart_fixme
      expect_no_offense(<<~RUBY)
        # FIXME(on: date('2019-08-04'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_optimize_is_a_smart_optimize
      expect_no_offense(<<~RUBY)
        # OPTIMIZE(on: date('2019-08-04'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_add_offense_when_fixme_has_invalid_format
      expect_offense(<<~RUBY)
        # FIXME(on: '2019-08-04', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:on` event format: "2019-08-04". For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_optimize_has_invalid_format
      expect_offense(<<~RUBY)
        # OPTIMIZE(on: '2019-08-04', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:on` event format: "2019-08-04". For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_tag_is_lower_case
      expect_offense(<<~RUBY)
        # todo(on: '2019-08-04', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_fixme_tag_is_lower_case
      expect_offense(<<~RUBY)
        # fixme(on: '2019-08-04', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_optimize_tag_is_lower_case
      expect_offense(<<~RUBY)
        # optimize(on: '2019-08-04', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_at_todo_is_used
      expect_offense(<<~RUBY)
        # @todo Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_at_todo_uppercase_is_used
      expect_offense(<<~RUBY)
        # @TODO Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_at_fixme_is_used
      expect_offense(<<~RUBY)
        # @fixme Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_at_fixme_uppercase_is_used
      expect_offense(<<~RUBY)
        # @FIXME Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_at_optimize_is_used
      expect_offense(<<~RUBY)
        # @optimize Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_at_optimize_uppercase_is_used
      expect_offense(<<~RUBY)
        # @OPTIMIZE Do this on January first
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_optimize_used_in_free_test_are_valid
      expect_no_offense(<<~RUBY)
        # optimized thing
        def hello
        end
      RUBY
    end

    def test_tags_used_in_free_test_are_valid
      expect_no_offense(<<~RUBY)
        # Todo list
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_valid_context_with_issue
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: 'john@example.com', context: "shopify/smart_todo#123")
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_context_with_different_events
      expect_no_offense(<<~RUBY)
        # TODO(on: gem_release('rails', '> 6.0'), to: 'john@example.com', context: "rails/rails#456")
        def hello
        end

        # TODO(on: gem_bump('rails', '> 7.0'), to: 'john@example.com', context: "rails/rails#789")
        def hello
        end

        # TODO(on: ruby_version('> 3.0'), to: 'john@example.com', context: "ruby/ruby#123")
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_context_with_wrong_number_of_arguments
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: 'john@example.com', context: "shopify/smart_todo")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:context` format: expected "org/repo#issue_number". For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_context_with_non_string_arguments
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: 'john@example.com', context: 123)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:context` format: expected string value. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_context_with_invalid_function
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: 'john@example.com', context: "shopify-smart_todo-123")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:context` format: expected "org/repo#issue_number". For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_context_does_not_require_assignee_when_event_does
      # Even though context is present, the TODO still requires an assignee for the event
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), context: "shopify/smart_todo#123")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_is_assigned_to_channel_without_owner
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#my-channel')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Missing `owner:` option. When assigning to a channel, you must specify an owner. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_is_assigned_to_channel_with_owner
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#my-channel', owner: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_is_assigned_to_email_without_owner
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_add_offense_when_todo_has_mixed_assignees_without_owner
      # If any assignee is a channel, owner is required
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#my-channel', to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Missing `owner:` option. When assigning to a channel, you must specify an owner. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_mixed_assignees_with_owner
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#my-channel', to: 'john@example.com', owner: 'jane@example.com')
        def hello
        end
      RUBY
    end

    def test_add_offense_when_owner_is_not_an_email
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#my-channel', owner: 'john')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:owner` format: expected email address. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    def test_add_offense_when_owner_is_not_a_string
      expect_offense(<<~RUBY)
        # TODO(on: date('2019-08-04'), to: '#my-channel', owner: 123)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ SmartTodo/SmartTodoCop: Invalid TODO format: Incorrect `:owner` format: expected email address. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
        def hello
        end
      RUBY
    end

    private

    def expected_message
      "SmartTodo/SmartTodoCop: Don't write regular TODO comments. Write SmartTodo compatible syntax comments. " \
        "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
    end

    def expect_offense(source)
      annotated_source = RuboCop::RSpec::ExpectOffense::AnnotatedSource.parse(source)
      report = investigate(annotated_source.plain_source)

      actual_annotations = annotated_source.with_offense_annotations(report.offenses)
      assert_equal(annotated_source.to_s, actual_annotations.to_s)
    end
    alias_method :expect_no_offense, :expect_offense

    def investigate(source, ruby_version = 2.5, file = "(file)")
      processed_source = RuboCop::ProcessedSource.new(source, ruby_version, file)

      assert(processed_source.valid_syntax?)
      comm = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
      comm.investigate(processed_source)
    end

    def cop
      @cop ||= RuboCop::Cop::SmartTodo::SmartTodoCop.new
    end
  end
end
