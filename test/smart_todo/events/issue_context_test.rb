# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class Events
    class IssueContextTest < Minitest::Test
      def test_when_issue_exists_and_is_open
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Add support for caching",
            number: 123,
            assignee: { login: "johndoe" },
          ))

        expected = "📌 Context: Issue #123 - \"Add support for caching\" [open] (@johndoe) - " \
          "https://github.com/rails/rails/issues/123"

        assert_equal(expected, issue_context("rails", "rails", "123"))
      end

      def test_when_issue_exists_and_is_closed
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "closed",
            title: "Fix memory leak",
            number: 456,
            assignee: { login: "janedoe" },
          ))

        expected = "📌 Context: Issue #456 - \"Fix memory leak\" [closed] (@janedoe) - " \
          "https://github.com/shopify/smart_todo/issues/456"

        assert_equal(expected, issue_context("shopify", "smart_todo", "456"))
      end

      def test_when_issue_has_no_assignee
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Improve documentation",
            number: 789,
            assignee: nil,
          ))

        expected = "📌 Context: Issue #789 - \"Improve documentation\" [open] (unassigned) - " \
          "https://github.com/org/repo/issues/789"

        assert_equal(expected, issue_context("org", "repo", "789"))
      end

      def test_when_issue_does_not_exist
        stub_request(:get, /api.github.com/)
          .to_return(status: 404)

        assert_nil(issue_context("rails", "rails", "999"))
      end

      def test_when_token_env_is_not_present
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Test issue",
            number: 1,
            assignee: nil,
          ))

        result = issue_context("rails", "rails", "1")
        assert(result.include?("📌 Context: Issue #1"))

        assert_requested(:get, /api.github.com/) do |request|
          assert(!request.headers.key?("Authorization"))
        end
      end

      def test_when_token_env_is_present
        ENV[GITHUB_TOKEN] = "abc123"

        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Test issue",
            number: 2,
            assignee: nil,
          ))

        result = issue_context("rails", "rails", "2")
        assert(result.include?("📌 Context: Issue #2"))

        assert_requested(:get, /api.github.com/) do |request|
          assert_equal("token abc123", request.headers["Authorization"])
        end
      ensure
        ENV.delete(GITHUB_TOKEN)
      end

      def test_when_organization_specific_token_is_present
        ENV["#{GITHUB_TOKEN}__RAILS"] = "rails_token"

        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Test issue",
            number: 3,
            assignee: nil,
          ))

        result = issue_context("rails", "rails", "3")
        assert(result.include?("📌 Context: Issue #3"))

        assert_requested(:get, /api.github.com/) do |request|
          assert_equal("token rails_token", request.headers["Authorization"])
        end
      ensure
        ENV.delete("#{GITHUB_TOKEN}__RAILS")
      end

      def test_when_repo_specific_token_is_present
        ENV["#{GITHUB_TOKEN}__RAILS__RAILS"] = "rails_rails_token"

        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Test issue",
            number: 4,
            assignee: nil,
          ))

        result = issue_context("rails", "rails", "4")
        assert(result.include?("📌 Context: Issue #4"))

        assert_requested(:get, /api.github.com/) do |request|
          assert_equal("token rails_rails_token", request.headers["Authorization"])
        end
      ensure
        ENV.delete("#{GITHUB_TOKEN}__RAILS__RAILS")
      end

      private

      def issue_context(*args)
        Events.new.issue_context(*args)
      end
    end
  end
end
