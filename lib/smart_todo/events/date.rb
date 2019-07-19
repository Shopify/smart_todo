# frozen_string_literal: true

require 'time'

module SmartTodo
  module Events
    # An event that check if the passed date is passed
    class Date
      # @param on_date [String] a string parsable by Time.parse
      # @return [String, false]
      def self.met?(on_date)
        if Time.now >= Time.parse(on_date)
          message(on_date)
        else
          false
        end
      end

      # @param on_date [String]
      # @return [String]
      def self.message(on_date)
        "We are past the *#{on_date}* due date and your TODO is now ready to be addressed."
      end
    end
  end
end
