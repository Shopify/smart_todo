# frozen_string_literal: true

require "test_helper"

module SmartTodo
  module Parser
    class MetadataParserTest < Minitest::Test
      def test_parse_todo_metadata_with_one_event
        ruby_code = <<~RUBY
          # TODO(on: date('2019-08-04'), to: 'john@example.com')
        RUBY

        result = Todo.new(ruby_code)
        assert_equal(1, result.events.size)
        assert_equal(:date, result.events[0].method_name)
        assert_equal(["john@example.com"], result.assignees)
      end

      def test_parse_todo_metadata_with_multiple_event
        ruby_code = <<~RUBY
          # TODO(on: date('2019-08-04'), on: gem_release('v1.2'), to: 'john@example.com')
        RUBY

        result = Todo.new(ruby_code)
        assert_equal(2, result.events.size)
        assert_equal(:date, result.events[0].method_name)
        assert_equal(:gem_release, result.events[1].method_name)
        assert_equal(["john@example.com"], result.assignees)
      end

      def test_parse_todo_metadata_with_no_assignee
        ruby_code = <<~RUBY
          # TODO(on: date('2019-08-04'))
        RUBY

        result = Todo.new(ruby_code)
        assert_equal(:date, result.events[0].method_name)
        assert_empty(result.assignees)
      end

      def test_parse_todo_metadata_with_multiple_assignees
        ruby_code = <<~RUBY
          # TODO(on: something('abc', '123', '456'), to: 'john@example.com', to: 'janne@example.com')
        RUBY

        result = Todo.new(ruby_code)
        assert_equal(:something, result.events[0].method_name)
        assert_equal(["abc", "123", "456"], result.events[0].arguments)
        assert_equal(["john@example.com", "janne@example.com"], result.assignees)
      end

      def test_parse_todo_metadata_with_repeated_assignees
        ruby_code = <<~RUBY
          # TODO(on: something('abc', '123', '456'), to: 'john@example.com', to: 'john@example.com')
        RUBY

        result = Todo.new(ruby_code)
        assert_equal(:something, result.events[0].method_name)
        assert_equal(["abc", "123", "456"], result.events[0].arguments)
        assert_equal(["john@example.com", "john@example.com"], result.assignees)
      end

      def test_parse_todo_metadata_with_multiple_arguments
        ruby_code = <<~RUBY
          # TODO(on: something('abc', '123', '456'), to: 'john@example.com')
        RUBY

        result = Todo.new(ruby_code)
        assert_equal(:something, result.events[0].method_name)
        assert_equal(["abc", "123", "456"], result.events[0].arguments)
        assert_equal(["john@example.com"], result.assignees)
      end

      def test_parse_when_todo_metadata_is_uncorrectly_formatted
        ruby_code = <<~RUBY
          # TODO(foo: 'bar', lol: 'ahah')
        RUBY

        result = Todo.new(ruby_code)
        assert_empty(result.events)
        assert_empty(result.assignees)
      end

      def test_parse_when_todo_metadata_on_is_uncorrectly_formatted
        ruby_code = <<~RUBY
          # TODO(on: '2019-08-04')
        RUBY

        result = Todo.new(ruby_code)

        assert_equal(["Incorrect `:on` event format: \"2019-08-04\""], result.errors)
      end

      def test_when_a_smart_todo_has_incorrect_ruby_syntax
        ruby_code = <<~EOM
          # TODO(A<<+<<)
          #   Revisit the way we say hello.
          def hello
          end
        EOM

        result = Todo.new(ruby_code)
        assert_empty(result.events)
        assert_empty(result.assignees)
      end

      def test_parse_when_todo_metadata_is_not_ruby_code
        ruby_code = <<~RUBY
          # TODO: Do this when done
        RUBY

        result = Todo.new(ruby_code)
        assert_empty(result.events)
        assert_empty(result.assignees)
      end
    end
  end
end
