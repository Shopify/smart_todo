# frozen_string_literal: true

require 'test_helper'
require 'time'

module SmartTodo
  module Events
    class DateTest < Minitest::Test
      def test_when_date_is_in_the_past
        Time.stub(:now, Time.parse('2019-07-04 02:57:18 +0000')) do
          assert_equal('We are past the *2019-07-03 02:57:18 +0000* due date', Date.met?('2019-07-03 02:57:18 +0000'))
        end
      end

      def test_met_when_date_is_in_the_future
        Time.stub(:now, Time.parse('2019-07-04 02:57:18 +0000')) do
          assert_equal(false, Date.met?('2019-07-07 02:57:18 +0000'))
        end
      end
    end
  end
end
