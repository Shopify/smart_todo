# frozen_string_literal: true

require "test_helper"
require "bundler"

module SmartTodo
  module Events
    class RubyVersionTest < Minitest::Test
      def test_when_a_single_ruby_version_is_met
        requirements = "2.5.7"
        ruby_version = RubyVersion.new(requirements)
        expectation = "The currently installed verion of Ruby 2.5.7 is = 2.5.7."

        ruby_version.stub(:installed_ruby_version, '2.5.7') do
          assert_equal(expectation, ruby_version.met?)
        end
      end

      def test_when_a_ruby_version_range_is_met
        requirements = [">= 2.5", "< 3"]
        ruby_version = RubyVersion.new(requirements)
        expectation = "The currently installed verion of Ruby 2.5.7 is >= 2.5, < 3."

        ruby_version.stub(:installed_ruby_version, '2.5.7') do
          assert_equal(expectation, ruby_version.met?)
        end
      end

      def test_when_a_pessimistic_ruby_version_is_met
        requirements = "~> 2.5"
        ruby_version = RubyVersion.new(requirements)
        expectation = "The currently installed verion of Ruby 2.7.3 is ~> 2.5."

        ruby_version.stub(:installed_ruby_version, '2.7.3') do
          assert_equal(expectation, ruby_version.met?)
        end
      end

      def test_when_a_single_ruby_version_is_not_met
        requirements = "2.5.7"
        ruby_version = RubyVersion.new(requirements)
        expectation = false

        ruby_version.stub(:installed_ruby_version, '2.5.6') do
          assert_equal(expectation, ruby_version.met?)
        end
      end

      def test_when_a_ruby_version_range_is_not_met
        requirements = [">= 2.5", "< 3"]
        ruby_version = RubyVersion.new(requirements)
        expectation = false

        ruby_version.stub(:installed_ruby_version, '3.2.1') do
          assert_equal(expectation, ruby_version.met?)
        end
      end

      def test_when_a_pessimistic_ruby_version_is_not_met
        requirements = "~> 2.5"
        ruby_version = RubyVersion.new(requirements)
        expectation = false

        ruby_version.stub(:installed_ruby_version, '3.2.1') do
          assert_equal(expectation, ruby_version.met?)
        end
      end
    end
  end
end
