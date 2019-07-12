# frozen_string_literal: true

require 'net/http'
require 'json'

module SmartTodo
  module Events
    class GemRelease
      def initialize(gem_name, requirements)
        @gem_name = gem_name
        @requirements = Gem::Requirement.new(requirements)
      end

      def met?
        response = client.get("/api/v1/versions/#{@gem_name}.json")

        if response.code_type < Net::HTTPClientError
          error_message
        elsif (gem = version_released?(response.body))
          message(gem['number'])
        else
          false
        end
      end

      def error_message
        "The gem *#{@gem_name}* doesn't seem to exist, I can't determine if your TODO is ready to be addressed."
      end

      def message(version_number)
        "The gem *#{@gem_name}* was released to version *#{version_number}* and your TODO is now ready to be addressed."
      end

      private

      def version_released?(gem_versions)
        JSON.parse(gem_versions).find do |gem|
          @requirements.satisfied_by?(Gem::Version.new(gem['number']))
        end
      end

      def client
        @client ||= Net::HTTP.new('rubygems.org', Net::HTTP.https_default_port).tap do |client|
          client.use_ssl = true
        end
      end
    end
  end
end
