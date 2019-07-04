# frozen_string_literal: true

require 'test_helper'

module SmartTodo
  module Parser
    class MetadataParserTest < Minitest::Test
      def test_parse_todo_metadata_with_one_event
        ruby_code = <<~RUBY
          on_date('2019-08-04') > assignee('john@example.com')
        RUBY

        result = MetadataParser.new(ruby_code).parse
        assert_equal('on_date', result.events[0].method_name)
        assert_equal('john@example.com', result.assignee[0])
      end

      def test_parse_todo_metadata_with_multiple_event
        ruby_code = <<~RUBY
          on_date('2019-08-04') | on_gem_release('v1.2') > assignee('john@example.com')
        RUBY

        result = MetadataParser.new(ruby_code).parse
        assert_equal(2, result.events.count)
        assert_equal('on_date', result.events[0].method_name)
        assert_equal('on_gem_release', result.events[1].method_name)
        assert_equal('john@example.com', result.assignee[0])
      end

      def test_parse_todo_metadata_with_no_assignee
        ruby_code = <<~RUBY
          on_date('2019-08-04') | on_gem_release('v1.2')
        RUBY

        result = MetadataParser.new(ruby_code).parse
        assert_equal(2, result.events.count)
        assert_equal('on_date', result.events[0].method_name)
        assert_equal('on_gem_release', result.events[1].method_name)
        assert_nil(result.assignee)
      end

      def test_parse_todo_metadata_with_multiple_arguments
        ruby_code = <<~RUBY
          on_date('a', 'b', 'c') | on_gem_release('d', 'e', 'f')
        RUBY

        result = MetadataParser.new(ruby_code).parse
        assert_equal(2, result.events.count)
        assert_equal('on_date', result.events[0].method_name)
        assert_equal(['a', 'b', 'c'], result.events[0])
        assert_equal('on_gem_release', result.events[1].method_name)
        assert_equal(['d', 'e', 'f'], result.events[1])
        assert_nil(result.assignee)
      end
    end
  end
end
