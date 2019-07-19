# frozen_string_literal: true

require 'net/http'
require 'json'

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
        @error_code = response_body['error']

        super("Response body: #{response_body}")
      end
    end

    # @param slack_token [String]
    def initialize(slack_token)
      @slack_token = slack_token
      @client = Net::HTTP.new('slack.com', Net::HTTP.https_default_port).tap do |client|
        client.use_ssl = true
        client.read_timeout = 30
        client.ssl_timeout = 15
      end
    end

    # Retrieve the Slack ID of a user from his email
    #
    # @param email [String]
    # @return [Hash]
    #
    # @raise [Net::HTTPError] in case the reques to Slack failed
    # @raise [SlackClient::Error] in case Slack returs a { ok: false } in the body
    #
    # @see https://api.slack.com/methods/users.lookupByEmail
    def lookup_user_by_email(email)
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      request(:get, "/api/users.lookupByEmail?email=#{email}", nil, headers)
    end

    # Send a message to a Slack channel or to a user
    #
    # @param channel [String] The Slack channel or the user ID
    # @param text [String] The message to send
    # @return [Hash]
    #
    # @raise [Net::HTTPError] in case the reques to Slack failed
    # @raise [SlackClient::Error] in case Slack returs a { ok: false } in the body
    #
    # @see https://api.slack.com/methods/chat.postMessage
    def post_message(channel, text)
      request(:post, '/api/chat.postMessage', JSON.dump(channel: channel, text: text))
    end

    private

    # @param method [Symbol]
    # @param endpoint [String]
    # @param data [String] JSON encoded data when making a POST request
    # @param headers [Hash]
    #
    # @raise [Net::HTTPError] in case the reques to Slack failed
    # @raise [SlackClient::Error] in case Slack returs a { ok: false } in the body
    def request(method, endpoint, data = nil, headers = {})
      response = case method
      when :post, :patch
        @client.public_send(method, endpoint, data, default_headers.merge(headers))
      else
        @client.public_send(method, endpoint, default_headers.merge(headers))
      end

      slack_response!(response)
    end

    # Chech if the response to Slack was a 200 and the Slack API request was successful
    #
    # @param response [Net::HTTPResponse] a net Net::HTTPResponse subclass
    #   (Net::HTTPOK, Net::HTTPNotFound ...)
    # @return [Hash]
    #
    # @raise [Net::HTTPError] in case the reques to Slack failed
    # @raise [SlackClient::Error] in case Slack returs a { ok: false } in the body
    def slack_response!(response)
      raise(Net::HTTPError.new('Request to slack failed', response)) unless response.code_type < Net::HTTPSuccess
      body = JSON.parse(response.body)

      if body['ok']
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
        'Content-Type' => 'application/json; charset=utf8',
        'Authorization' => "Bearer #{@slack_token}",
      }
    end
  end
end
