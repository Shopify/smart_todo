# frozen_string_literal: true

require "test_helper"
require "time"

module SmartTodo
  class Events
    class DateTest < Minitest::Test
      def test_when_date_is_in_the_past
        events = Events.new(now: Time.parse("2019-07-04 02:57:18 +0000"))

        expected = "We are past the *2019-07-03 02:57:18 +0000* due date and your TODO is now ready to be addressed."
        assert_equal(expected, events.date("2019-07-03 02:57:18 +0000"))
      end

      def test_met_when_date_is_in_the_future
        events = Events.new(now: Time.parse("2019-07-04 02:57:18 +0000"))

        assert_equal(false, events.date("2019-07-07 02:57:18 +0000"))
      end
    end
  end
end
