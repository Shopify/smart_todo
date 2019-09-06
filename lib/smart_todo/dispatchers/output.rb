# frozen_string_literal: true

module SmartTodo
  module Dispatchers
    # A simple dispatcher that will output the reminder.
    class Output < Base
      def self.validate_options!(_); end

      # @return void
      def dispatch
        puts slack_message({})
      end
    end
  end
end
