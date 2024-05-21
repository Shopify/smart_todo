# frozen_string_literal: true

require "cgi"
require "net/http"
require "json"

module SmartTodo
  # A simple client around the Slack API.
  #
  # @example Sending a  message to a user.
  #   SmartTodo::SlackClient.new.post_message('#general', 'Hello!')
  class SlackClient
    # A generic error class raised when the Slack API returns back a 200
    # but there was a problem (permission issues ...)
    class Error < StandardError
      attr_reader :error_code

      # @param response_body [Hash] the parsed response body from Slack
      def initialize(response_body)
        @error_code = response_body["error"]

        super("Response body: #{response_body}")
      end
    end

    # @param slack_token [String]
    def initialize(slack_token)
      @slack_token = slack_token
      @client = HttpClientBuilder.build("slack.com")
    end

    # Retrieve the Slack ID of a user from his email
    #
    # @param email [String]
    # @return [Hash]
    #
    # @raise [Net::HTTPError] in case the request to Slack failed
    # @raise [SlackClient::Error] in case Slack returns a { ok: false } in the body
    #
    # @see https://api.slack.com/methods/users.lookupByEmail
    def lookup_user_by_email(email)
      headers = default_headers.merge("Content-Type" => "application/x-www-form-urlencoded")
      request = Net::HTTP::Get.new("/api/users.lookupByEmail?email=#{CGI.escape(email)}", headers)
      dispatch(request)
    end

    # Send a message to a Slack channel or to a user
    #
    # @param channel [String] The Slack channel or the user ID
    # @param text [String] The message to send
    # @return [Hash]
    #
    # @raise [Net::HTTPError] in case the request to Slack failed
    # @raise [SlackClient::Error] in case Slack returns a { ok: false } in the body
    #
    # @see https://api.slack.com/methods/chat.postMessage
    def post_message(channel, text)
      headers = default_headers
      request = Net::HTTP::Post.new("/api/chat.postMessage", headers)
      request.body = JSON.dump(channel: channel, text: text)
      dispatch(request)
    end

    private

    # @param method [Symbol]
    # @param endpoint [String]
    # @param data [String] JSON encoded data when making a POST request
    # @param headers [Hash]
    #
    # @raise [Net::HTTPError] in case the request to Slack failed
    # @raise [SlackClient::Error] in case Slack returns a { ok: false } in the body
    def dispatch(request, max_attempts = 5)
      response = @client.request(request)
      attempts = 1

      while response.is_a?(Net::HTTPTooManyRequests) && attempts < max_attempts
        sleep([Integer(response["Retry-After"]), 600].min)
        response = @client.request(request)
        attempts += 1
      end

      unless response.code_type < Net::HTTPSuccess
        raise(Net::HTTPError.new("Request to slack failed", response))
      end

      body = JSON.parse(response.body)

      if body["ok"]
        body
      else
        raise(Error, body)
      end
    end

    # The default headers required by Slack
    #
    # @return [Hash]
    def default_headers
      {
        "Content-Type" => "application/json; charset=utf8",
        "Authorization" => "Bearer #{@slack_token}",
      }
    end
  end
end
