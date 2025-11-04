# frozen_string_literal: true

require "test_helper"

module SmartTodo
  module Dispatchers
    class OutputTest < Minitest::Test
      def setup
        @options = { fallback_channel: "#general", slack_token: "123", repo: "example" }
      end

      def test_dispatch_with_github_link
        dispatcher = Output.new("Foo", todo_node, "file.rb", @options)

        output = capture_io { dispatcher.dispatch }[0]

        # Verify it includes a GitHub link (we're in the smart_todo repo)
        assert_match(%r{<https://github.com/Shopify/smart_todo/blob/[^/]+/file\.rb#L1\|file\.rb:1>}, output)
        assert_match(/Foo/, output)
        assert_match(/Hello :wave:,/, output)
      end

      def test_dispatch_without_github_link
        @options[:base_path] = "/tmp/non-git"
        dispatcher = Output.new("Foo", todo_node, "file.rb", @options)
        expected_text = <<~HEREDOC
          Hello :wave:,

          You have an assigned TODO in the `file.rb` file on line 1 in repository `example`.
          Foo

          Here is the associated comment on your TODO:

          ```

          ```
        HEREDOC

        assert_output(expected_text) { dispatcher.dispatch }
      end

      private

      def todo_node(*assignees)
        tos = assignees.map { |assignee| "to: '#{assignee}'" }
        tos << "to: 'john@example.com'" if assignees.empty?

        ruby_code = <<~EOM
          # TODO(on: date('2011-03-02'), #{tos.join(", ")})
          def hello
          end
        EOM

        CommentParser.parse(ruby_code)[0]
      end
    end
  end
end
