# frozen_string_literal: true

require "test_helper"
require "bundler"

module SmartTodo
  module Events
    class GemBumpTest < Minitest::Test
      def test_when_gem_is_released
        bump = GemBump.new("rubocop", "0.71")
        expected = "The gem *rubocop* was updated to version *0.71.0* and your TODO is now ready to be addressed."

        bump.stub(:spec_set, fake_bundler_specs) do
          assert_equal(expected, bump.met?)
        end
      end

      def test_with_pessimistic_constraint
        bump = GemBump.new("rubocop", "~>0.50")
        expected = "The gem *rubocop* was updated to version *0.71.0* and your TODO is now ready to be addressed."

        bump.stub(:spec_set, fake_bundler_specs) do
          assert_equal(expected, bump.met?)
        end
      end

      def test_with_multiple_constraints
        bump = GemBump.new("rubocop", ["> 0.50", "< 1"])
        expected = "The gem *rubocop* was updated to version *0.71.0* and your TODO is now ready to be addressed."

        bump.stub(:spec_set, fake_bundler_specs) do
          assert_equal(expected, bump.met?)
        end
      end

      def test_when_gem_is_not_yet_released
        bump = GemBump.new("rubocop", "1")

        bump.stub(:spec_set, fake_bundler_specs) do
          assert_equal(false, bump.met?)
        end
      end

      def test_when_gem_does_not_exist
        bump = GemBump.new("beep_boop", "1")
        expected =
          "The gem *beep_boop* is not in your dependencies, I can't determine if your TODO is ready to be addressed."

        bump.stub(:spec_set, fake_bundler_specs) do
          assert_equal(expected, bump.met?)
        end
      end

      def fake_bundler_specs
        @fake_bundler_specs ||= Bundler::SpecSet.new(
          Bundler::LockfileParser.new(Bundler.read_file("test/smart_todo/fixtures/Gemfile.lock")).specs
        )
      end
    end
  end
end
