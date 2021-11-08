# frozen_string_literal: true

require "test_helper"
require "tempfile"

module SmartTodo
  class CLITest < Minitest::Test
    def test_adds_current_directory_if_none_is_passed
      cli = CLI.new

      Dir.stub(:[], []) do
        paths = cli.run(["--slack_token", "123", "--fallback_channel", '#general"'])

        assert_equal(["."], paths)
      end
    end

    def test_dispatch_slack_message_when_a_todo_is_met
      cli = CLI.new
      ruby_code = <<~EOM
        # TODO(on: date('2015-03-01'), to: 'john@example.com')
        #   Revisit the way we say hello.
        #   Please.
        def hello
        end
      EOM

      mock = Minitest::Mock.new
      mock.expect(:dispatch, nil)

      generate_ruby_file(ruby_code) do |file|
        Dispatchers::Slack.stub(:new, mock) do
          cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"', "--dispatcher", "slack"])
        end
      end

      assert_mock(mock)
    end

    def test_does_not_dispatch_slack_message_when_a_todo_is_unmet
      cli = CLI.new
      ruby_code = <<~EOM
        # TODO(on: date('2070-03-01'), to: 'john@example.com')
        #   Revisit the way we say hello.
        #   Please.
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"'])
      end

      assert_not_requested(:post, /chat.postMessage/)
    end

    def test_ascii_encoded_file_with_utf8_characters_can_be_parsed_correctly
      previous_encoding = Encoding.default_external
      Encoding.default_external = "US-ASCII"

      cli = CLI.new
      ruby_code = <<~EOM
        # See "市区町村名"
        def hello
        end

        # TODO(on: date('2070-03-02'), to: '#general')
        #   See "市区町村名"
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"'])
      end

      assert_not_requested(:post, /chat.postMessage/)
    ensure
      Encoding.default_external = previous_encoding
    end

    def test_does_not_crash_if_the_event_is_incorrectly_formated
      cli = CLI.new
      ruby_code = <<~EOM
        # TODO(on: '2010-03-02', to: '#general')
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"'])
      end

      assert_not_requested(:post, /chat.postMessage/)
    end
  end
end
