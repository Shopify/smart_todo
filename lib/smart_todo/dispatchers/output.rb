# frozen_string_literal: true

module SmartTodo
  module Dispatchers
    # A simple dispatcher that will output the reminder.
    class Output < Base
      class << self
        def validate_options!(_); end
      end

      # @return void
      def dispatch
        puts slack_message({}, nil)
      end
    end
  end
end
