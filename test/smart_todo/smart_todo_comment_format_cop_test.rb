# frozen_string_literal: true

require "test_helper"
require "rubocop"
require "rubocop/rspec/expect_offense"
require "smart_todo_comment_format_cop"

module SmartTodo
  class SmartTodoCommentFormatCopTest < Minitest::Test
    def test_add_offense_when_comment_on_same_line_with_colon
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com'): Remove this
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg_inline}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_comment_on_same_line_without_colon
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com') Remove this
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg_inline}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_continuation_line_not_indented
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        # Remove this
        ^^^^^^^^^^^^^ #{msg_indent}
        def hello
        end
      RUBY
    end

    def test_add_offense_when_continuation_line_partially_indented
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        #  Remove this (only 1 space instead of 2)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg_indent}
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_properly_formatted
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        #   Remove this
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_no_continuation_line
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_continuation_line_is_empty
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        #
        def hello
        end
      RUBY
    end

    def test_does_not_add_offense_when_continuation_is_another_todo
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        # FIXME(on: date('2024-04-01'), to: 'jane@example.com')
        def hello
        end
      RUBY
    end

    def test_autocorrect_inline_comment_with_colon
      expect_correction(
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com'): Remove this
          def hello
          end
        RUBY
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com')
          #   Remove this
          def hello
          end
        RUBY
      )
    end

    def test_autocorrect_inline_comment_without_colon
      expect_correction(
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com') Remove this
          def hello
          end
        RUBY
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com')
          #   Remove this
          def hello
          end
        RUBY
      )
    end

    def test_autocorrect_unindented_continuation
      expect_correction(
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com')
          # Remove this
          def hello
          end
        RUBY
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com')
          #   Remove this
          def hello
          end
        RUBY
      )
    end

    def test_autocorrect_partially_indented_continuation
      expect_correction(
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com')
          #  Remove this
          def hello
          end
        RUBY
        <<~RUBY,
          # TODO(on: date('2024-03-29'), to: 'john@example.com')
          #   Remove this
          def hello
          end
        RUBY
      )
    end

    def test_works_with_fixme_tag
      expect_offense(<<~RUBY)
        # FIXME(on: date('2024-03-29'), to: 'john@example.com'): Fix this
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg_inline}
        def hello
        end
      RUBY
    end

    def test_works_with_optimize_tag
      expect_offense(<<~RUBY)
        # OPTIMIZE(on: date('2024-03-29'), to: 'john@example.com'): Optimize this
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg_inline}
        def hello
        end
      RUBY
    end

    def test_multiline_continuation_properly_formatted
      expect_no_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        #   Remove pre_launch_enabled from settings
        #   and update the tests accordingly
        def hello
        end
      RUBY
    end

    def test_multiline_continuation_improperly_formatted
      expect_offense(<<~RUBY)
        # TODO(on: date('2024-03-29'), to: 'john@example.com')
        # Remove pre_launch_enabled from settings
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg_indent}
        # and update the tests accordingly
        def hello
        end
      RUBY
    end

    private

    def msg_inline
      "SmartTodo/SmartTodoCommentFormatCop: SmartTodo comment must not be on the same line as the TODO. " \
        "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
    end

    def msg_indent
      "SmartTodo/SmartTodoCommentFormatCop: SmartTodo continuation line must be indented by 2 spaces. " \
        "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
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

    def expect_correction(source, expected)
      file = "(file)"
      processed_source = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, file)

      assert(processed_source.valid_syntax?)

      comm = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
      report = comm.investigate(processed_source)

      # Apply corrections
      corrector = RuboCop::Cop::Corrector.new(processed_source)
      report.offenses.each do |offense|
        corrector.merge!(offense.corrector) if offense.corrector
      end

      corrected_source = corrector.rewrite

      assert_equal(expected, corrected_source)
    end

    def investigate(source, file = "(file)")
      processed_source = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f, file)

      assert(processed_source.valid_syntax?)
      comm = RuboCop::Cop::Commissioner.new([cop], [], raise_error: true)
      comm.investigate(processed_source)
    end

    def cop
      # Always create a new cop instance to avoid state issues
      RuboCop::Cop::SmartTodo::SmartTodoCommentFormatCop.new
    end
  end
end
