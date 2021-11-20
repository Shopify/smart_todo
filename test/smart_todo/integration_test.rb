# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class IntegrationTest < Minitest::Test
    def test_sends_a_slack_message_when_date_is_met
      ruby_code = <<~EOM
        # TODO(on: date('2015-03-01'), to: 'john@example.com')
        #   Revisit the way we say hello.
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        run_cli(file)
      end

      assert_slack_message_sent(
        "Hello :wave:,",
        "We are past the *2015-03-01* due date"
      )
    end

    def test_sends_a_slack_message_when_gem_release_is_met
      ruby_code = <<~EOM
        # TODO(on: gem_release('rails', '> 5.1'), to: 'john@example.com')
        #   Revisit the way we say hello.
        def hello
        end
      EOM

      stub_request(:get, /rubygems.org/)
        .to_return(body: JSON.dump([{ number: "5.1.1" }]))

      generate_ruby_file(ruby_code) do |file|
        run_cli(file)
      end

      assert_slack_message_sent(
        "Hello :wave:,",
        "The gem *rails* was released to version *5.1.1*"
      )
    end

    def test_sends_a_slack_message_when_pull_request_close_is_met
      ruby_code = <<~EOM
        # TODO(on: pull_request_close('shopify', 'shopify', 123), to: 'john@example.com')
        #   Revisit the way we say hello.
        def hello
        end
      EOM

      stub_request(:get, /api.github.com/)
        .to_return(body: JSON.dump(state: "closed"))

      generate_ruby_file(ruby_code) do |file|
        run_cli(file)
      end

      assert_slack_message_sent(
        "Hello :wave:,",
        "The Pull Request or Issue https://github.com/shopify/shopify/pull/123\nis now closed"
      )
    end

    def test_sends_a_slack_message_when_issue_close_is_met
      ruby_code = <<~EOM
        # TODO(on: issue_close('shopify', 'shopify', 123), to: 'john@example.com')
        #   Revisit the way we say hello.
        def hello
        end
      EOM

      stub_request(:get, /api.github.com/)
        .to_return(body: JSON.dump(state: "closed"))

      generate_ruby_file(ruby_code) do |file|
        run_cli(file)
      end

      assert_slack_message_sent(
        "Hello :wave:,",
        "The Pull Request or Issue https://github.com/shopify/shopify/pull/123\nis now closed"
      )
    end

    private

    def assert_slack_message_sent(*messages)
      assert_requested(:post, /chat.postMessage/) do |request|
        request_body = JSON.parse(request.body)

        messages.each do |message|
          assert_match(message, request_body["text"])
        end
      end
    end

    def stub_slack_request
      stub_request(:get, /users.lookupByEmail/)
        .to_return(body: JSON.dump(ok: true, user: { id: "ABC", profile: { first_name: "John" } }))

      stub_request(:post, /chat.postMessage/)
        .to_return(body: JSON.dump(ok: true))
    end

    def run_cli(file)
      stub_slack_request

      CLI.new.run([file.path, "--slack_token", "123", "--fallback_channel", '#general"', "--dispatcher", "slack"])
    end
  end
end
