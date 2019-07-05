# frozen_string_literal: true

module SmartTodo
  module Events
    extend self

    def on_date(date)
      Date.met?(date)
    end
  end
end
