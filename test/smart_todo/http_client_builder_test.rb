# frozen_string_literal: true

require "test_helper"
require "tempfile"

module SmartTodo
  class HttpBuilderTest < Minitest::Test
    def test_builds_http_client_with_proper_config
      client = HttpClientBuilder.build("example.com")

      assert_equal("example.com", client.address)
      assert_equal(15, client.ssl_timeout)
      assert_equal(30, client.read_timeout)
      assert_equal(2, client.max_retries)
    end
  end
end
