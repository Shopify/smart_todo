# frozen_string_literal: true

require 'net/http'
require 'json'

module SmartTodo
  module Events
    class GemRelease
      def initialize(gem_name, version)
        @gem_name = gem_name
        @version = version
      end

      def met?
        response = client.get("/api/v1/versions/#{@gem_name}.json")

        if response.code_type < Net::HTTPClientError
          error_message
        elsif version_released?(response.body)
          message
        else
          false
        end
      end

      def error_message
        "The gem *#{@gem_name}* doesn't seem to exist, I can't determine if your TODO is ready to be addressed."
      end

      def message
        "The gem *#{@gem_name}* was released to version *#{@version}* and your TODO is now ready to be addressed."
      end

      private

      def version_released?(gem_versions)
        JSON.parse(gem_versions).find { |gem| gem['number'] == @version }
      end

      def client
        @client ||= Net::HTTP.new('rubygems.org', Net::HTTP.https_default_port).tap do |client|
          client.use_ssl = true
        end
      end
    end
  end
end
