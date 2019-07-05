# frozen_string_literal: true

require 'time'

module SmartTodo
  module Events
    class Date
      def self.met?(on_date)
        if Time.now >= Time.parse(on_date)
          message(on_date)
        else
          false
        end
      end

      def self.message(on_date)
        "We are past the *#{on_date}* due date"
      end
    end
  end
end
