# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class Events
    class IssueCloseTest < Minitest::Test
      def test_when_pull_request_is_close
        stub_request(:get, /api.github.com/)
          .to_return_json(body: { state: "closed" })

        expected =
          "The pull request https://github.com/rails/rails/pull/123 is now closed, your TODO is ready to be addressed."

        assert_equal(expected, pull_request_close("rails", "rails", "123"))
      end

      def test_when_pull_request_is_open
        stub_request(:get, /api.github.com/)
          .to_return_json(body: { state: "open" })

        assert_equal(false, pull_request_close("rails", "rails", "123"))
      end

      def test_when_gem_does_not_exist
        stub_request(:get, /api.github.com/)
          .to_return(status: 404)

        expected = <<~EOM
          I can't retrieve the information from the PR *123* in the *rails/rails* repository.

          If the repository is a private one, make sure to export the `#{GITHUB_TOKEN}`
          environment variable with a correct GitHub token.
        EOM

        assert_equal(expected, pull_request_close("rails", "rails", "123"))
      end

      def test_when_token_env_is_not_present
        stub_request(:get, /api.github.com/)
          .to_return_json(body: { state: "open" })

        assert_equal(false, pull_request_close("rails", "rails", "123"))

        assert_requested(:get, /api.github.com/) do |request|
          assert(!request.headers.key?("Authorization"))
        end
      end

      def test_when_token_env_is_present
        with_env(Events::GITHUB_TOKEN => "abc") do
          stub_request(:get, /api.github.com/)
            .to_return_json(body: { state: "open" })

          assert_equal(false, pull_request_close("rails", "rails", "123"))

          assert_requested(:get, /api.github.com/) do |request|
            assert_equal("token abc", request.headers["Authorization"])
          end
        end
      end

      def test_when_org_token_env_is_present
        with_env(
          Events::GITHUB_TOKEN + "__RAILS" => "abcd",
          Events::GITHUB_TOKEN => "abc",
        ) do
          stub_request(:get, /api.github.com/)
            .to_return_json(body: { state: "open" })

          assert_equal(false, pull_request_close("rails", "rails", "123"))

          assert_requested(:get, /api.github.com/) do |request|
            assert_equal("token abcd", request.headers["Authorization"])
          end
        end
      end

      def test_when_repo_org_token_env_is_present
        with_env(
          Events::GITHUB_TOKEN + "__SHOPIFY__SMART_TODO" => "abcde",
          Events::GITHUB_TOKEN + "__SHOPIFY" => "abcd",
          Events::GITHUB_TOKEN => "abc",
        ) do
          stub_request(:get, /api.github.com/)
            .to_return_json(body: { state: "open" })

          assert_equal(false, pull_request_close("Shopify", "smart-todo", "123"))

          assert_requested(:get, /api.github.com/) do |request|
            assert_equal("token abcde", request.headers["Authorization"])
          end
        end
      end

      def test_calls_the_right_endpoint_when_type_is_pull_request
        expected_endpoint = "https://api.github.com/repos/rails/rails/pulls/123"
        stub_request(:get, expected_endpoint)
          .to_return_json(body: { state: "open" })

        assert_equal(false, pull_request_close("rails", "rails", "123"))
        assert_requested(:get, expected_endpoint)
      end

      def test_calls_the_right_endpoint_when_type_is_issue
        expected_endpoint = "https://api.github.com/repos/rails/rails/issues/123"
        stub_request(:get, expected_endpoint)
          .to_return_json(body: { state: "open" })

        assert_equal(false, issue_close("rails", "rails", "123"))
        assert_requested(:get, expected_endpoint)
      end

      private

      def issue_close(organization, repo, issue_number)
        Events.new.issue_close(organization, repo, issue_number)
      end

      def pull_request_close(organization, repo, pr_number)
        Events.new.pull_request_close(organization, repo, pr_number)
      end

      def with_env(env = {})
        original_env = ENV.to_h
        ENV.merge!(env)
        yield
      ensure
        ENV.replace(original_env)
      end
    end
  end
end
