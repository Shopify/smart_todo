# frozen_string_literal: true

require "test_helper"
require "tempfile"

module SmartTodo
  class CLITest < Minitest::Test
    def test_adds_current_directory_if_none_is_passed
      cli = CLI.new

      Dir.stub(:[], []) do
        check_path = ->(path) do
          assert_equal(".", path)
          []
        end

        cli.stub(:normalize_path, check_path) do
          assert_output("") do
            assert_equal(0, cli.run(["--slack_token", "123", "--fallback_channel", '#general"']))
          end
        end
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
          assert_output(".") do
            assert_equal(
              0,
              cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"', "--dispatcher", "slack"]),
            )
          end
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
        assert_output(".") do
          assert_equal(0, cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"']))
        end
      end

      assert_not_requested(:post, /chat.postMessage/)
    end

    def test_ascii_encoded_file_with_utf8_characters_can_be_parsed_correctly
      previous_verbose = $VERBOSE
      previous_encoding = Encoding.default_external

      begin
        $VERBOSE = nil
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
          assert_output(".") do
            assert_equal(0, cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"']))
          end
        end

        assert_not_requested(:post, /chat.postMessage/)
      ensure
        Encoding.default_external = previous_encoding
        $VERBOSE = previous_verbose
      end
    end

    def test_does_not_crash_if_the_event_is_incorrectly_formatted
      cli = CLI.new
      ruby_code = <<~EOM
        # TODO(on: '2010-03-02', to: '#general')
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        assert_output(".", /Incorrect `:on` event format: "2010-03-02"/) do
          assert_equal(1, cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"']))
        end
      end

      assert_not_requested(:post, /chat.postMessage/)
    end

    def test_exist_with_error_when_files_can_not_be_parsed
      cli = CLI.new
      ruby_code = <<~EOM
        # TODO(on: date(2010-03-02), to: '#general')
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        assert_output(".", /Incorrect `:on` event format: date\(2010-03-02\)/) do
          assert_equal(1, cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"']))
        end
      end
    end

    def test_exist_with_error_when_files_can_not_be_parsed_1
      cli = CLI.new
      ruby_code = <<~EOM
        # TODO(on: issue_close(211), to: '#general')
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        assert_output(
          ".",
          /Error while parsing .* on event `issue_close` with arguments \["211"\]: wrong number of arguments \(given 1, expected 3\)/, # rubocop:disable Layout/LineLength
        ) do
          assert_equal(1, cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"']))
        end
      end
    end

    def test_if_repository_config_read_correctly
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
          assert_output(".") do
            assert_equal(
              0,
              cli.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"', "--dispatcher", "slack", "--read-repository-config"]),
            )
          end
        end
      end

      assert_mock(mock)
    end
  end
end
