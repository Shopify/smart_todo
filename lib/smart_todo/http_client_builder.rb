# frozen_string_literal: true

require "net/http"

module SmartTodo
  # @api private
  class HttpClientBuilder
    class << self
      def build(endpoint)
        Net::HTTP.new(endpoint, Net::HTTP.https_default_port).tap do |client|
          client.use_ssl = true
          client.read_timeout = 30
          client.ssl_timeout = 15
          client.max_retries = 2
        end
      end
    end
  end
end
