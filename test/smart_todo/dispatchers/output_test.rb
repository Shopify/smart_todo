# frozen_string_literal: true

require "test_helper"

module SmartTodo
  module Dispatchers
    class OutputTest < Minitest::Test
      def setup
        @options = { fallback_channel: "#general", slack_token: "123" }
        @test_config_content = <<~HEREDOC
          [remote "origin"]
            url = git@github.com:org_name/repo_name.git
          [user]
            name = John Doe
            email = john@example.com
        HEREDOC
      end

      def test_dispatch
        dispatcher = Output.new("Foo", todo_node, "file.rb", @options)
        expected_text = <<~HEREDOC
          Hello :wave:,

          You have an assigned TODO in the `file.rb` file.
          Foo

          Here is the associated comment on your TODO:

          ```

          ```
        HEREDOC

        assert_output(expected_text) { dispatcher.dispatch }
      end

      def test_github_url
        File.stub(:readlines, @test_config_content.lines) do
          @options[:repository_config] = GitConfigParser.new
          dispatcher = Output.new("Foo", todo_node, "file.rb", @options)
          expected_text = <<~HEREDOC
            Hello :wave:,

            You have an assigned TODO in the `https://github.com/org_name/repo_name/blob/HEAD/file.rb` file.
            Foo

            Here is the associated comment on your TODO:

            ```

            ```
          HEREDOC

          assert_output(expected_text) { dispatcher.dispatch }
        end
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
