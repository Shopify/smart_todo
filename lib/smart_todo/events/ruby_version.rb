# frozen_string_literal: true

module SmartTodo
  module Events
    # An event that checks the currently installed ruby version.
    # @example
    #   RubyVersion.new(['>= 2.3', '< 3'])
    class RubyVersion
      def initialize(requirements)
        @requirements = Gem::Requirement.new(requirements)
      end

      # @param requirements [Array<String>] a list of version specifiers
      # @return [String, false]
      def met?
        if @requirements.satisfied_by?(Gem::Version.new(installed_ruby_version))
          message(installed_ruby_version)
        else
          false
        end
      end

      # @param installed_ruby_version [String], requirements [String]
      # @return [String]
      def message(installed_ruby_version)
        "The currently installed verion of Ruby #{installed_ruby_version} is #{@requirements}."
      end

      private

      def installed_ruby_version
        RUBY_VERSION
      end
    end
  end
end
