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
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{expected_message}
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
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid event method(s): data. For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax
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

    private

    def expected_message
      "Don't write regular TODO comments. Write SmartTodo compatible syntax comments. " \
        "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
    end

    def expect_offense(source)
      annotated_source = RuboCop::RSpec::ExpectOffense::AnnotatedSource.parse(source)
      investigate(annotated_source.plain_source)

      actual_annotations = annotated_source.with_offense_annotations(cop.offenses)
      assert_equal(actual_annotations.to_s, annotated_source.to_s)
    end
    alias_method :expect_no_offense, :expect_offense

    def investigate(source, ruby_version = 2.5, file = "(file)")
      processed_source = RuboCop::ProcessedSource.new(source, ruby_version, file)

      RuboCop::Cop::Commissioner.new([cop], [], raise_error: true).tap do |commissioner|
        commissioner.investigate(processed_source)
      end
    end

    def cop
      @cop ||= RuboCop::Cop::SmartTodo::SmartTodoCop.new
    end
  end
end
