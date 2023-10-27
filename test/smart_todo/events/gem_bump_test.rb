# frozen_string_literal: true

require "test_helper"
require "bundler"

module SmartTodo
  class Events
    class GemBumpTest < Minitest::Test
      def test_when_gem_is_released
        expected = "The gem *rubocop* was updated to version *0.71.0* and your TODO is now ready to be addressed."

        assert_equal(expected, gem_bump("rubocop", "0.71"))
      end

      def test_with_pessimistic_constraint
        expected = "The gem *rubocop* was updated to version *0.71.0* and your TODO is now ready to be addressed."

        assert_equal(expected, gem_bump("rubocop", "~>0.50"))
      end

      def test_with_multiple_constraints
        expected = "The gem *rubocop* was updated to version *0.71.0* and your TODO is now ready to be addressed."

        assert_equal(expected, gem_bump("rubocop", "> 0.50", "< 1"))
      end

      def test_when_gem_is_not_yet_released
        assert_equal(false, gem_bump("rubocop", "1"))
      end

      def test_when_gem_does_not_exist
        expected =
          "The gem *beep_boop* is not in your dependencies, I can't determine if your TODO is ready to be addressed."

        assert_equal(expected, gem_bump("beep_boop", "1"))
      end

      private

      def gem_bump(gem_name, *requirements)
        Events.new(spec_set: fake_bundler_specs).gem_bump(gem_name, *requirements)
      end

      def fake_bundler_specs
        @fake_bundler_specs ||= Bundler::SpecSet.new(
          Bundler::LockfileParser.new(Bundler.read_file("test/smart_todo/fixtures/Gemfile.lock")).specs,
        )
      end
    end
  end
end
