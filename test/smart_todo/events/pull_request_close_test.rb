# frozen_string_literal: true

require 'test_helper'

module SmartTodo
  module Events
    class PullRequestCloseTest < Minitest::Test
      def test_when_pull_request_is_close
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: 'closed'))

        expected = <<~EOM
          The Pull Request or Issue *123* in the *rails/rails* repository
          is now closed, your TODO is ready to be addressed.
        EOM
        assert_equal(expected, PullRequestClose.new('rails', 'rails', '123').met?)
      end

      def test_when_pull_request_is_open
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: 'open'))

        assert_equal(false, PullRequestClose.new('rails', 'rails', '123').met?)
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

        assert_equal(expected, PullRequestClose.new('rails', 'rails', '123').met?)
      end

      def test_when_token_env_is_not_present
        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: 'open'))

        assert_equal(false, PullRequestClose.new('rails', 'rails', '123').met?)

        assert_requested(:get, /api.github.com/) do |request|
          assert(!request.headers.key?('Authorization'))
        end
      end

      def test_when_token_env_is_present
        ENV[PullRequestClose::TOKEN_ENV] = 'abc'

        stub_request(:get, /api.github.com/)
          .to_return(body: JSON.dump(state: 'open'))

        assert_equal(false, PullRequestClose.new('rails', 'rails', '123').met?)

        assert_requested(:get, /api.github.com/) do |request|
          assert(request.headers.key?('Authorization'))
        end
      ensure
        ENV.delete(PullRequestClose::TOKEN_ENV)
      end
    end
  end
end
