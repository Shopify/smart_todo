# frozen_string_literal: true

module SmartTodo
  module Events
    extend self

    def on_date(date)
      Date.met?(date)
    end

    def on_gem_release(gem_name, version)
      GemRelease.new(gem_name, version).met?
    end
  end
end
