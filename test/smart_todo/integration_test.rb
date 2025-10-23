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
        "We are past the *2015-03-01* due date",
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
        "The gem *rails* was released to version *5.1.1*",
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
        "The pull request https://github.com/shopify/shopify/pull/123 is now closed",
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
        "The issue https://github.com/shopify/shopify/issues/123 is now closed",
      )
    end

    def test_sends_a_slack_message_when_ruby_version_is_met
      ruby_code = <<~EOM
        # TODO(on: ruby_version('< 100.0.0'), to: 'john@example.com')
        #   Upgrade some gem.
        def hello
        end
      EOM

      generate_ruby_file(ruby_code) do |file|
        run_cli(file)
      end

      assert_slack_message_sent(
        "Hello :wave:,",
        "The currently installed version of Ruby #{RUBY_VERSION} is < 100.0.0.",
        "Upgrade some gem.",
      )
    end

    def test_outputs_issue_pin_information_without_sending_notification
      ruby_code = <<~EOM
        # TODO(on: issue_pin('shopify', 'smart_todo', '123'))
        #   Remember to update the caching strategy
        def hello
        end
      EOM

      stub_request(:get, /api.github.com/)
        .to_return(body: JSON.dump(
          state: "open",
          title: "Improve caching",
          number: 123,
          assignee: { login: "developer" },
        ))

      generate_ruby_file(ruby_code) do |file|
        # Run CLI with output dispatcher to see results
        output = capture_subprocess_io do
          CLI.new.run([file.path, "--dispatcher", "output"])
        end.join

        # Check that the issue information is in the output
        assert_match(/📌 Pinned to issue #123/, output)
        assert_match(/Improve caching/, output)
      end
    end

    def test_sends_notification_when_issue_pin_has_assignee
      ruby_code = <<~EOM
        # TODO(on: issue_pin('shopify', 'smart_todo', '456'), to: 'team@example.com')
        #   Don't forget about the refactoring
        def hello
        end
      EOM

      stub_request(:get, /api.github.com/)
        .to_return(body: JSON.dump(
          state: "closed",
          title: "Refactor authentication",
          number: 456,
          assignee: nil,
        ))

      generate_ruby_file(ruby_code) do |file|
        run_cli(file)
      end

      assert_slack_message_sent(
        "Hello :wave:,",
        "📌 Pinned to issue #456",
        "Refactor authentication",
        "Don't forget about the refactoring",
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
