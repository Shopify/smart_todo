# frozen_string_literal: true

require "test_helper"

module SmartTodo
  module Dispatchers
    class SlackTest < Minitest::Test
      def setup
        @options = { fallback_channel: "#general", slack_token: "123" }
      end

      def test_when_user_exists
        stub_request(:get, /users.lookupByEmail/)
          .to_return_json(body: { ok: true, user: { id: "ABC", profile: { first_name: "John" } } })
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node, "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/) do |request|
          request_body = JSON.parse(request.body)

          refute_match("this user or channel doesn't exist on Slack anymore", request_body["text"])
          assert_equal("ABC", request_body["channel"])
        end
      end

      def test_when_user_does_not_exist
        stub_request(:get, /users.lookupByEmail/)
          .to_return_json(body: { ok: false, error: "users_not_found" })
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node, "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/) do |request|
          request_body = JSON.parse(request.body)

          assert_match("this user or channel doesn't exist on Slack anymore", request_body["text"])
          assert_equal("#general", request_body["channel"])
        end
      end

      def test_when_channel_does_not_exist
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: false, error: "channel_not_found" })
          .then
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node("#my_channel"), "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/, body: /`#my_channel` had an assigned TODO/) do |request|
          request_body = JSON.parse(request.body)

          assert_match("this user or channel doesn't exist on Slack anymore", request_body["text"])
          assert_equal("#general", request_body["channel"])
        end
      end

      def test_when_channel_is_archived
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: false, error: "is_archived" })
          .then
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node("#my_channel"), "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/, body: /`#my_channel` had an assigned TODO/) do |request|
          request_body = JSON.parse(request.body)

          assert_match("this user or channel doesn't exist on Slack anymore", request_body["text"])
          assert_equal("#general", request_body["channel"])
        end
      end

      def test_raises_when_lookup_by_email_fails
        stub_request(:get, /users.lookupByEmail/)
          .to_return_json(body: { ok: false, error: "fatal_error" })

        dispatcher = Slack.new("Foo", todo_node, "file.rb", @options)

        _, stderr = capture_io do
          dispatcher.dispatch
        end

        assert_match(
          /Error finding user or channel: Response body: .*"fatal_error".*/,
          stderr,
        )
      end

      def test_when_user_is_a_slack_channel
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node("#my_channel"), "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/) do |request|
          request_body = JSON.parse(request.body)

          refute_match("this user or channel doesn't exist on Slack anymore", request_body["text"])
          assert_equal("#my_channel", request_body["channel"])
        end
      end

      def test_when_multiple_assignees
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node("#my_channel1", "#my_channel2"), "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/, times: 2) do |request|
          request_body = JSON.parse(request.body)
          assert_includes(["#my_channel1", "#my_channel2"], request_body["channel"])
        end
      end

      def test_validate_options_when_all_mandatory_options_are_passed
        Slack.validate_options!(slack_token: "123", fallback_channel: "#general")
      end

      def test_validate_options_when_token_option_passed_is_empty_string
        error = assert_raises(ArgumentError) do
          Slack.validate_options!(slack_token: "", fallback_channel: "#general")
        end

        assert_equal("Missing :slack_token", error.message)
      ensure
        ENV.delete("SMART_TODO_SLACK_TOKEN")
      end

      def test_validate_options_when_token_option_is_missing
        error = assert_raises(ArgumentError) do
          Slack.validate_options!(fallback_channel: "#general")
        end

        assert_equal("Missing :slack_token", error.message)
      end

      def test_validate_options_when_token_option_env_is_empty_string
        previous_token = ENV["SMART_TODO_SLACK_TOKEN"]
        ENV["SMART_TODO_SLACK_TOKEN"] = ""
        error = assert_raises(ArgumentError) do
          Slack.validate_options!(fallback_channel: "#general")
        end

        assert_equal("Missing :slack_token", error.message)
      ensure
        ENV["SMART_TODO_SLACK_TOKEN"] = previous_token
      end

      def test_when_slack_token_option_is_in_the_environment
        previous_token = ENV["SMART_TODO_SLACK_TOKEN"]
        ENV["SMART_TODO_SLACK_TOKEN"] = "123"
        options = { fallback_channel: "#general" }

        Slack.validate_options!(options)

        assert_equal("123", options[:slack_token])
      ensure
        ENV["SMART_TODO_SLACK_TOKEN"] = previous_token
      end

      def test_when_fallback_channel_is_missing
        error = assert_raises(ArgumentError) do
          Slack.validate_options!(slack_token: "123")
        end

        assert_equal("Missing :fallback_channel", error.message)
      end

      def test_includes_owner_when_specified
        stub_request(:get, /users.lookupByEmail/)
          .to_return_json(body: { ok: true, user: { id: "OWNER123", profile: { first_name: "Jane" } } })
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node_with_owner, "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/) do |request|
          request_body = JSON.parse(request.body)
          assert_match(/Owner: <@OWNER123>/, request_body["text"])
        end
      end

      def test_excludes_owner_when_not_specified
        stub_request(:get, /users.lookupByEmail/)
          .to_return_json(body: { ok: true, user: { id: "ABC", profile: { first_name: "John" } } })
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node, "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/) do |request|
          request_body = JSON.parse(request.body)
          refute_match(/Owner:/, request_body["text"])
        end
      end

      def test_excludes_owner_when_slack_lookup_fails
        # First call for owner lookup fails, second for assignee succeeds
        stub_request(:get, /users.lookupByEmail/)
          .to_return_json(body: { ok: false, error: "users_not_found" })
          .then
          .to_return_json(body: { ok: true, user: { id: "ABC", profile: { first_name: "John" } } })
        stub_request(:post, /chat.postMessage/)
          .to_return_json(body: { ok: true })

        dispatcher = Slack.new("Foo", todo_node_with_owner, "file.rb", @options)
        dispatcher.dispatch

        assert_requested(:post, /chat.postMessage/) do |request|
          request_body = JSON.parse(request.body)
          refute_match(/Owner:/, request_body["text"])
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

      def todo_node_with_owner
        ruby_code = <<~EOM
          # TODO(on: date('2011-03-02'), to: '#my-channel', owner: 'jane@example.com')
          def hello
          end
        EOM

        CommentParser.parse(ruby_code)[0]
      end
    end
  end
end
