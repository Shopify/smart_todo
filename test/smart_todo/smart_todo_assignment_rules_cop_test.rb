# frozen_string_literal: true

require "test_helper"
require "rubocop"
require "rubocop/rspec/expect_offense"
require "smart_todo_assignment_rules_cop"

module SmartTodo
  class AssignmentRulesTest < Minitest::Test
    def test_add_offense_when_smart_todo_missing_all_required_assignees
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something
        def hello
        end
      RUBY
    end

    def test_add_offense_when_smart_todo_missing_one_required_assignee
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_single("@team-lead")}
        #   Do something
        def hello
        end
      RUBY
    end

    def test_add_offense_when_smart_todo_has_different_assignees
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com', to: '#other-channel')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_smart_todo_has_all_required_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Do something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_smart_todo_has_required_assignees_first
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: '#project-alerts', to: '@team-lead', to: 'john@example.com')
        #   Do something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_smart_todo_has_required_assignees_only
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: '#project-alerts', to: '@team-lead')
        #   Do something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_smart_todo_has_required_assignees_among_multiple
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead', to: 'jane@example.com')
        #   Do something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_comment_is_not_a_todo
      expect_no_offense(<<~RUBY)
        # This is a regular comment
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_is_not_smart
      expect_no_offense(<<~RUBY)
        # TODO: Do this later
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_todo_has_event_but_no_assignee
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'))
        def hello
        end
      RUBY
    end

    def test_add_offense_when_fixme_missing_required_assignees
      expect_offense(<<~RUBY)
        # FIXME(on: date('2024-03-29'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Fix something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_fixme_has_required_assignees
      expect_no_offense(<<~RUBY)
        # FIXME(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Fix something
        def hello
        end
      RUBY
    end

    def test_add_offense_when_optimize_missing_required_assignees
      expect_offense(<<~RUBY)
        # OPTIMIZE(on: date('2024-03-29'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Optimize something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_optimize_has_required_assignees
      expect_no_offense(<<~RUBY)
        # OPTIMIZE(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Optimize something
        def hello
        end
      RUBY
    end

    def test_add_offense_with_issue_close_event
      expect_offense(<<~RUBY)
        # TODO(on: issue_close('shopify', 'smart_todo', '123'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something when issue closes
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_issue_close_event_and_all_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: issue_close('shopify', 'smart_todo', '123'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Do something when issue closes
        def hello
        end
      RUBY
    end

    def test_add_offense_with_pull_request_close_event
      expect_offense(<<~RUBY)
        # TODO(on: pull_request_close('shopify', 'smart_todo', '456'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something when PR closes
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_pull_request_close_event_and_all_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: pull_request_close('shopify', 'smart_todo', '456'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Do something when PR closes
        def hello
        end
      RUBY
    end

    def test_add_offense_with_gem_release_event
      expect_offense(<<~RUBY)
        # TODO(on: gem_release('rails', '>= 7.0'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something when gem is released
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_gem_release_event_and_all_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: gem_release('rails', '>= 7.0'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Do something when gem is released
        def hello
        end
      RUBY
    end

    def test_add_offense_with_gem_bump_event
      expect_offense(<<~RUBY)
        # TODO(on: gem_bump('rails', '>= 8.0'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something when gem is bumped
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_gem_bump_event_and_all_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: gem_bump('rails', '>= 8.0'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Do something when gem is bumped
        def hello
        end
      RUBY
    end

    def test_add_offense_with_ruby_version_event
      expect_offense(<<~RUBY)
        # TODO(on: ruby_version('>= 3.0'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something when ruby version changes
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_ruby_version_event_and_all_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: ruby_version('>= 3.0'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        #   Do something when ruby version changes
        def hello
        end
      RUBY
    end

    def test_add_offense_with_lowercase_todo
      expect_offense(<<~RUBY)
        # todo(on: date('2024-03-29'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_lowercase_todo_and_all_assignees
      expect_no_offense(<<~RUBY)
        # todo(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
        def hello
        end
      RUBY
    end

    def test_add_offense_with_multiple_smart_todos
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something

        # FIXME(on: date('2024-04-15'), to: 'jane@example.com')
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Fix something
        def hello
        end
      RUBY
    end

    def test_add_offense_with_context_but_missing_assignees
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com', context: "shopify/smart_todo#123")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message_multiple}
        #   Do something
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_with_context_and_all_assignees
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead', context: "shopify/smart_todo#123")
        #   Do something
        def hello
        end
      RUBY
    end

    private

    def expected_message_single(assignee)
      "Smart TODO must include required assignee: #{assignee}"
    end

    def expected_message_multiple
      "Smart TODO must include required assignees: #project-alerts, @team-lead"
    end

    def expect_offense(source)
      annotated_source = RuboCop::RSpec::ExpectOffense::AnnotatedSource.parse(source)
      report = investigate(annotated_source.plain_source)

      actual_annotations = annotated_source.with_offense_annotations(report.offenses)
      assert_equal(annotated_source.to_s, actual_annotations.to_s)
    end

    def expect_no_offense(source)
      annotated_source = RuboCop::RSpec::ExpectOffense::AnnotatedSource.parse(source)
      report = investigate(annotated_source.plain_source)

      assert_empty(report.offenses, "Expected no offenses but got: #{report.offenses.map(&:message).join(", ")}")
    end

    def investigate(source, file = "(file)")
      processed_source = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, file)

      assert(processed_source.valid_syntax?)
      comm = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
      comm.investigate(processed_source)
    end

    def cop
      # Create a new cop instance with the required configuration
      config = RuboCop::Config.new(
        {
          "SmartTodo/AssignmentRules" => {
            "RequiredAssignees" => ["#project-alerts", "@team-lead"],
          },
        },
        "(config)",
      )
      RuboCop::Cop::SmartTodo::AssignmentRules.new(config)
    end
  end
end
