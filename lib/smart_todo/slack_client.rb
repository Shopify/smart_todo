# frozen_string_literal: true

require 'net/http'
require 'json'

module SmartTodo
  class SlackClient
    class Error < StandardError
      attr_reader :error_code

      def initialize(response_body)
        @error_code = response_body['error']

        super("Response body: #{response_body}")
      end
    end

    def initialize(slack_token)
      @slack_token = slack_token
      @client = Net::HTTP.new('slack.com', Net::HTTP.https_default_port).tap do |client|
        client.use_ssl = true
        client.read_timeout = 30
        client.ssl_timeout = 15
      end
    end

    def lookup_user_by_email(email)
      headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      request(:get, "/api/users.lookupByEmail?email=#{email}", nil, headers)
    end

    def post_message(channel, text)
      request(:post, '/api/chat.postMessage', JSON.dump(channel: channel, text: text))
    end

    private

    def request(method, endpoint, data = nil, headers = {})
      response = case method
      when :post, :patch
        @client.public_send(method, endpoint, data, default_headers.merge(headers))
      else
        @client.public_send(method, endpoint, default_headers.merge(headers))
      end

      slack_response!(response)
    end

    def slack_response!(response)
      raise(Net::HTTPError.new('Request to slack failed', response)) unless response.code_type < Net::HTTPSuccess
      body = JSON.parse(response.body)

      if body['ok']
        body
      else
        raise(Error, body)
      end
    end

    def default_headers
      {
        'Content-Type' => 'application/json; charset=utf8',
        'Authorization' => "Bearer #{@slack_token}",
      }
    end
  end
end
