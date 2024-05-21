# frozen_string_literal: true

require "test_helper"
require "json"

module SmartTodo
  class SlackClientTest < Minitest::Test
    def setup
      @client = SlackClient.new("123")
    end

    def test_lookup_user_by_email_when_user_exists
      stub_request(:get, /slack.com/)
        .to_return(body: JSON.dump(ok: true))

      @client.lookup_user_by_email("john@example.com")

      assert_requested(:get, /slack.com/) do |request|
        assert_equal("application/x-www-form-urlencoded", request.headers["Content-Type"])
        assert_equal("Bearer 123", request.headers["Authorization"])
        assert_equal("john@example.com", request.uri.query_values["email"])
      end
    end

    def test_lookup_user_by_email_when_user_does_not_exist
      stub_request(:get, /slack.com/)
        .to_return(body: JSON.dump(ok: false, error: "users_not_found"))

      error = assert_raises(SlackClient::Error) do
        @client.lookup_user_by_email("john@example.com")
      end
      assert_equal("users_not_found", error.error_code)
    end

    def test_post_message_is_successful
      stub_request(:post, /slack.com/)
        .to_return(body: JSON.dump(ok: true))

      @client.post_message("#XT-123", "Hello!")

      assert_requested(:post, /slack.com/) do |request|
        assert_equal("application/json; charset=utf8", request.headers["Content-Type"])
        assert_equal("Bearer 123", request.headers["Authorization"])
        assert_equal({ "channel" => "#XT-123", "text" => "Hello!" }, JSON.parse(request.body))
      end
    end

    def test_post_message_fails
      stub_request(:post, /slack.com/)
        .to_return(body: JSON.dump(ok: false, error: "too_many_request"))

      error = assert_raises(SlackClient::Error) do
        @client.post_message("#XT-123", "Hello!")
        @client.lookup_user_by_email("john@example.com")
      end
      assert_equal("too_many_request", error.error_code)
    end

    def test_raises_a_net_http_error
      stub_request(:get, /slack.com/)
        .to_return(status: 404)

      assert_raises(Net::HTTPError) do
        @client.lookup_user_by_email("john@example.com")
      end
    end

    def test_succeeds_when_reponse_is_a_201
      stub_request(:get, /slack.com/)
        .to_return(status: 201, body: JSON.dump(ok: true))

      @client.lookup_user_by_email("john@example.com")
    end

    def test_handles_sleeping
      counter = 0

      stub_request(:get, /slack.com/).to_return do
        counter += 1
        if counter == 1
          { status: 429, headers: { "Retry-After" => "1" } }
        else
          { status: 201, body: JSON.dump(ok: true) }
        end
      end

      @client.lookup_user_by_email("john@example.com")
    end

    def test_fails_sleeping
      stub_request(:get, /slack.com/)
        .to_return(status: 429, headers: { "Retry-After" => "0" })

      assert_raises(Net::HTTPError) do
        @client.lookup_user_by_email("john@example.com")
      end
    end
  end
end
