# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class Events
    class IssuePinTest < Minitest::Test
      def test_when_issue_is_open
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Add support for caching",
            number: 123,
            assignee: { login: "johndoe" },
          ))

        expected = "📌 Pinned to issue #123: \"Add support for caching\" [open] (@johndoe) - " \
          "https://github.com/rails/rails/issues/123"

        assert_equal(expected, issue_pin("rails", "rails", "123"))
      end

      def test_when_issue_is_closed
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "closed",
            title: "Fix memory leak",
            number: 456,
            assignee: { login: "janedoe" },
          ))

        expected = "📌 Pinned to issue #456: \"Fix memory leak\" [closed] (@janedoe) - " \
          "https://github.com/shopify/smart_todo/issues/456"

        assert_equal(expected, issue_pin("shopify", "smart_todo", "456"))
      end

      def test_when_issue_has_no_assignee
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Improve documentation",
            number: 789,
            assignee: nil,
          ))

        expected = "📌 Pinned to issue #789: \"Improve documentation\" [open] (unassigned) - " \
          "https://github.com/org/repo/issues/789"

        assert_equal(expected, issue_pin("org", "repo", "789"))
      end

      def test_when_issue_does_not_exist
        stub_request(:get, /api.github.com/)
          .to_return(status: 404)

        expected = <<~EOM
          I can't retrieve the information from the issue *999* in the *rails/rails* repository.

          If the repository is a private one, make sure to export the `#{GITHUB_TOKEN}`
          environment variable with a correct GitHub token.
        EOM

        assert_equal(expected, issue_pin("rails", "rails", "999"))
      end

      def test_when_token_env_is_not_present
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(
            state: "open",
            title: "Test issue",
            number: 1,
            assignee: nil,
          ))

        result = issue_pin("rails", "rails", "1")
        assert(result.include?("📌 Pinned to issue #1"))

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

        result = issue_pin("rails", "rails", "2")
        assert(result.include?("📌 Pinned to issue #2"))

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

        result = issue_pin("rails", "rails", "3")
        assert(result.include?("📌 Pinned to issue #3"))

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

        result = issue_pin("rails", "rails", "4")
        assert(result.include?("📌 Pinned to issue #4"))

        assert_requested(:get, /api.github.com/) do |request|
          assert_equal("token rails_rails_token", request.headers["Authorization"])
        end
      ensure
        ENV.delete("#{GITHUB_TOKEN}__RAILS__RAILS")
      end

      private

      def issue_pin(*args)
        Events.new.issue_pin(*args)
      end
    end
  end
end
