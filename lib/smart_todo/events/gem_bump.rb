# frozen_string_literal: true

gem('bundler')
require 'bundler'

module SmartTodo
  module Events
    # An event that compare the version of a gem specified in your Gemfile.lock
    # with the expected version specifiers.
    class GemBump
      # @param gem_name [String]
      # @param requirements [Array] a list of version specifiers.
      #   The specifiers are the same as the one used in Gemfiles or Gemspecs
      #
      # @example Expecting a specific version
      #   GemBump.new('rails', ['6.0'])
      #
      # @example Expecting a version in the 5.x.x series
      #   GemBump.new('rails', ['> 5.2', '< 6'])
      def initialize(gem_name, requirements)
        @gem_name = gem_name
        @requirements = Gem::Requirement.new(requirements)
      end

      # @return [String, false]
      def met?
        return error_message if spec_set[@gem_name].empty?

        installed_version = spec_set[@gem_name].first.version
        if @requirements.satisfied_by?(installed_version)
          message(installed_version)
        else
          false
        end
      end

      # Error message send to Slack in case a gem couldn't be found
      #
      # @return [String]
      def error_message
        "The gem *#{@gem_name}* is not in your dependencies, I can't determine if your TODO is ready to be addressed."
      end

      # @return [String]
      def message(version_number)
        "The gem *#{@gem_name}* was updated to version *#{version_number}* and your TODO is now ready to be addressed."
      end

      private

      # @return [Bundler::SpecSet] an instance of Bundler::SpecSet
      def spec_set
        @spec_set ||= Bundler.load.specs
      end
    end
  end
end
