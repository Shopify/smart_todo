# frozen_string_literal: true

require "test_helper"

module SmartTodo
  module Events
    class IssueCloseTest < Minitest::Test
      def test_when_pull_request_is_close
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: "closed"))

        expected = <<~EOM
          The Pull Request or Issue https://github.com/rails/rails/pull/123
          is now closed, your TODO is ready to be addressed.
        EOM
        assert_equal(expected, IssueClose.new("rails", "rails", "123", type: "pulls").met?)
      end

      def test_when_pull_request_is_open
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: "open"))

        assert_equal(false, IssueClose.new("rails", "rails", "123", type: "pulls").met?)
      end

      def test_when_gem_does_not_exist
        stub_request(:get, /api.github.com/)
          .to_return(status: 404)

        expected = <<~EOM
          I can't retrieve the information from the PR or Issue *123* in the
          *rails/rails* repository.

          If the repository is a private one, make sure to export the `SMART_TODO_GITHUB_TOKEN`
          environment variable with a correct GitHub token.
        EOM

        assert_equal(expected, IssueClose.new("rails", "rails", "123", type: "pulls").met?)
      end

      def test_when_token_env_is_not_present
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: "open"))

        assert_equal(false, IssueClose.new("rails", "rails", "123", type: "pulls").met?)

        assert_requested(:get, /api.github.com/) do |request|
          assert(!request.headers.key?("Authorization"))
        end
      end

      def test_when_token_env_is_present
        with_env(IssueClose::TOKEN_ENV => "abc") do
          stub_request(:get, /api.github.com/)
            .to_return(body: JSON.dump(state: "open"))

          assert_equal(false, IssueClose.new("rails", "rails", "123", type: "pulls").met?)

          assert_requested(:get, /api.github.com/) do |request|
            assert_equal("token abc", request.headers["Authorization"])
          end
        end
      end

      def test_when_org_token_env_is_present
        with_env(
          IssueClose::TOKEN_ENV + "__RAILS" => "abcd",
          IssueClose::TOKEN_ENV => "abc",
        ) do
          stub_request(:get, /api.github.com/)
            .to_return(body: JSON.dump(state: "open"))

          assert_equal(false, IssueClose.new("rails", "rails", "123", type: "pulls").met?)

          assert_requested(:get, /api.github.com/) do |request|
            assert_equal("token abcd", request.headers["Authorization"])
          end
        end
      end

      def test_when_repo_org_token_env_is_present
        with_env(
          IssueClose::TOKEN_ENV + "__SHOPIFY__SMART_TODO" => "abcde",
          IssueClose::TOKEN_ENV + "__SHOPIFY" => "abcd",
          IssueClose::TOKEN_ENV => "abc",
        ) do
          stub_request(:get, /api.github.com/)
            .to_return(body: JSON.dump(state: "open"))

          assert_equal(false, IssueClose.new("Shopify", "smart-todo", "123", type: "pulls").met?)

          assert_requested(:get, /api.github.com/) do |request|
            assert_equal("token abcde", request.headers["Authorization"])
          end
        end
      end

      def test_calls_the_right_endpoint_when_type_is_pull_request
        expected_endpoint = "https://api.github.com/repos/rails/rails/pulls/123"
        stub_request(:get, expected_endpoint)
          .to_return(body: JSON.dump(state: "open"))

        assert_equal(false, IssueClose.new("rails", "rails", "123", type: "pulls").met?)
        assert_requested(:get, expected_endpoint)
      end

      def test_calls_the_right_endpoint_when_type_is_issue
        expected_endpoint = "https://api.github.com/repos/rails/rails/issues/123"
        stub_request(:get, expected_endpoint)
          .to_return(body: JSON.dump(state: "open"))

        assert_equal(false, IssueClose.new("rails", "rails", "123", type: "issues").met?)
        assert_requested(:get, expected_endpoint)
      end

      private

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
