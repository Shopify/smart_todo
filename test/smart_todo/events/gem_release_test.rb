# frozen_string_literal: true

require "test_helper"

module SmartTodo
  class Events
    class GemReleaseTest < Minitest::Test
      def test_when_gem_is_released
        stub_request(:get, /rubygems.org/)
          .to_return(body: JSON.dump([{ number: "1.2.0" }]))

        expected = "The gem *foo* was released to version *1.2.0* and your TODO is now ready to be addressed."
        assert_equal(expected, gem_release("foo", "1.2.0"))
      end

      def test_with_pessimistic_constraint
        stub_request(:get, /rubygems.org/)
          .to_return(body: JSON.dump([{ number: "1.2.0" }]))

        expected = "The gem *foo* was released to version *1.2.0* and your TODO is now ready to be addressed."
        assert_equal(expected, gem_release("foo", "~> 1.1"))
      end

      def test_with_multiple_constraints
        stub_request(:get, /rubygems.org/)
          .to_return(body: JSON.dump([{ number: "3.4.6" }]))

        expected = "The gem *foo* was released to version *3.4.6* and your TODO is now ready to be addressed."
        assert_equal(expected, gem_release("foo", "> 3.4.3", "< 4"))
      end

      def test_when_gem_is_not_yet_released
        stub_request(:get, /rubygems.org/)
          .to_return(body: JSON.dump([{ number: "1.2.0" }, { number: "1.2.1" }]))

        assert_equal(false, gem_release("foo", "1.3.0"))
      end

      def test_when_gem_does_not_exist
        stub_request(:get, /rubygems.org/)
          .to_return(status: 404)

        expected = "The gem *foo* doesn't seem to exist, I can't determine if your TODO is ready to be addressed."
        assert_equal(expected, gem_release("foo", "1.3.0"))
      end

      private

      def gem_release(gem_name, *requirements)
        Events.new.gem_release(gem_name, *requirements)
      end
    end
  end
end
