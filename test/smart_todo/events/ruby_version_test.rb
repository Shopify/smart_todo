# frozen_string_literal: true

require "test_helper"
require "bundler"

module SmartTodo
  class Events
    class RubyVersionTest < Minitest::Test
      def test_when_a_single_ruby_version_is_met
        expectation = "The currently installed version of Ruby 2.5.7 is = 2.5.7."

        assert_equal(expectation, ruby_version(Gem::Version.new("2.5.7"), "2.5.7"))
      end

      def test_when_a_ruby_version_range_is_met
        expectation = "The currently installed version of Ruby 2.5.7 is >= 2.5, < 3."

        assert_equal(expectation, ruby_version(Gem::Version.new("2.5.7"), ">= 2.5", "< 3"))
      end

      def test_when_a_pessimistic_ruby_version_is_met
        expectation = "The currently installed version of Ruby 2.7.3 is ~> 2.5."

        assert_equal(expectation, ruby_version(Gem::Version.new("2.7.3"), "~> 2.5"))
      end

      def test_when_a_single_ruby_version_is_not_met
        expectation = false

        assert_equal(expectation, ruby_version(Gem::Version.new("2.5.6"), "2.5.7"))
      end

      def test_when_a_ruby_version_range_is_not_met
        expectation = false

        assert_equal(expectation, ruby_version(Gem::Version.new("3.2.1"), ">= 2.5", "< 3"))
      end

      def test_when_a_pessimistic_ruby_version_is_not_met
        expectation = false

        assert_equal(expectation, ruby_version(Gem::Version.new("3.2.1"), "~> 2.5"))
      end

      private

      def ruby_version(current_ruby_version, *requirements)
        Events.new(current_ruby_version: current_ruby_version).ruby_version(*requirements)
      end
    end
  end
end
