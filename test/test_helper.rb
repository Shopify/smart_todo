# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "smart_todo"

require "minitest/autorun"
require "minitest/mock"
require "webmock/minitest"

module Minitest
  class Test
    def generate_ruby_file(ruby_code)
      tempfile = Tempfile.open(["file", ".rb"]) do |file|
        file.write(ruby_code)
        file.rewind
        file
      end

      yield(tempfile)
    ensure
      tempfile.delete
    end
  end
end
