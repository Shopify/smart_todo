# frozen_string_literal: true

require "test_helper"

module SmartTodo
  module Dispatchers
    class OutputTest < Minitest::Test
      def test_dispatch_prints_the_expected_message
        dispatcher = Output.new("Foo", todo_node, "file.rb", {})
        assert_output(/Hello \:wave\:\,/) do
          dispatcher.dispatch
        end
      end

      private

      def todo_node
        ruby_code = <<~EOM
          # TODO(on: date('2011-03-02'), to: 'john@example.com'")
          def hello
          end
        EOM

        Parser::CommentParser.new(ruby_code).parse[0]
      end
    end
  end
end
