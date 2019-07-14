# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

module SmartTodo
  class CLITest < Minitest::Test
    def test_when_all_mandatory_options_are_passed
      cli = CLI.new
      paths = cli.run([__FILE__, '--slack_token', '123', '--fallback_channel', '#general"'])

      assert_equal([__FILE__], paths)
    end

    def test_when_slack_token_option_is_missing
      cli = CLI.new

      error = assert_raises(ArgumentError) do
        cli.run([__FILE__, '--fallback_channel', '"#general"'])
      end
      assert_equal('Missing :slack_token', error.message)
    end

    def test_when_slack_token_option_is_in_the_environment
      ENV['SMART_TODO_SLACK_TOKEN'] = '123'
      cli = CLI.new
      paths = cli.run([__FILE__, '--fallback_channel', '"#general"'])

      assert_equal([__FILE__], paths)
    ensure
      ENV.delete('SMART_TODO_SLACK_TOKEN')
    end

    def test_when_fallback_channel_is_missing
      cli = CLI.new

      error = assert_raises(ArgumentError) do
        cli.run([__FILE__, '--slack_token', '123'])
      end
      assert_equal('Missing :fallback_channel', error.message)
    end

    def test_adds_current_directory_if_none_is_passed
      cli = CLI.new

      Dir.stub(:[], []) do
        paths = cli.run(['--slack_token', '123', '--fallback_channel', '#general"'])

        assert_equal(['.'], paths)
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

      generate_ruby_file(ruby_code) do |file|
        stub_slack_request
        cli.run([file.path, '--slack_token', '123', '--fallback_channel', '#general"'])
      end

      assert_requested(:post, /chat.postMessage/) do |request|
        request_body = JSON.parse(request.body)

        assert_match('Hello John', request_body['text'])
        assert_match('We are past the *2015-03-01* due date', request_body['text'])
      end
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
        cli.run([file.path, '--slack_token', '123', '--fallback_channel', '#general"'])
      end

      assert_not_requested(:post, /chat.postMessage/)
    end

    private

    def stub_slack_request
      stub_request(:get, /users.lookupByEmail/)
        .to_return(body: JSON.dump(ok: true, user: { id: 'ABC', profile: { first_name: 'John' } }))

      stub_request(:post, /chat.postMessage/)
        .to_return(body: JSON.dump(ok: true))
    end

    def generate_ruby_file(ruby_code)
      tempfile = Tempfile.open(['file', '.rb']) do |file|
        file.write(ruby_code)
        file.rewind
        file
      end

      yield(tempfile)
    ensure
      tempfile.delete
    end
  end
end
