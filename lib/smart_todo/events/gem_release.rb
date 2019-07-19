# frozen_string_literal: true

require 'net/http'
require 'json'

module SmartTodo
  module Events
    # An event that check if a new version of gem has been released on RubyGem
    # with the expected version specifiers.
    # This event will make an API call to the RubyGem API
    class GemRelease
      # @param gem_name [String]
      # @param requirements [Array] a list of version specifiers.
      #   The specifiers are the same as the one used in Gemfiles or Gemspecs
      #
      # @example Expecting a specific version
      #   GemRelease.new('rails', ['6.0'])
      #
      # @example Expecting a version in the 5.x.x series
      #   GemRelease.new('rails', ['> 5.2', '< 6'])
      def initialize(gem_name, requirements)
        @gem_name = gem_name
        @requirements = Gem::Requirement.new(requirements)
      end

      # @return [String, false]
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

      # Error message send to Slack in case a gem couldn't be found
      #
      # @return [String]
      def error_message
        "The gem *#{@gem_name}* doesn't seem to exist, I can't determine if your TODO is ready to be addressed."
      end

      # @return [String]
      def message(version_number)
        "The gem *#{@gem_name}* was released to version *#{version_number}* and your TODO is now ready to be addressed."
      end

      private

      # @param gem_versions [String] the response sent from RubyGems
      # @return [true, false]
      def version_released?(gem_versions)
        JSON.parse(gem_versions).find do |gem|
          @requirements.satisfied_by?(Gem::Version.new(gem['number']))
        end
      end

      # @return [Net::HTTP] an instance of Net::HTTP
      def client
        @client ||= Net::HTTP.new('rubygems.org', Net::HTTP.https_default_port).tap do |client|
          client.use_ssl = true
        end
      end
    end
  end
end
