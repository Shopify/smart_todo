# frozen_string_literal: true

require 'test_helper'

module SmartTodo
  module Events
    class GemReleaseTest < Minitest::Test
      def test_when_gem_is_released
        stub_request(:get, /rubygems.org/)
          .to_return(body: JSON.dump([{ number: '1.2.0' }]))

        expected = 'The gem *foo* was released to version *1.2.0* and your TODO is now ready to be addressed.'
        assert_equal(expected, GemRelease.new('foo', '1.2.0').met?)
      end

      def test_when_gem_is_not_yet_released
        stub_request(:get, /rubygems.org/)
          .to_return(body: JSON.dump([{ number: '1.2.0' }, { number: '1.2.1' }]))

        assert_equal(false, GemRelease.new('foo', '1.3.0').met?)
      end

      def test_when_gem_does_not_exist
        stub_request(:get, /rubygems.org/)
          .to_return(status: 404)

        expected = "The gem *foo* doesn't seem to exist, I can't determine if your TODO is ready to be addressed."
        assert_equal(expected, GemRelease.new('foo', '1.3.0').met?)
      end
    end
  end
end
