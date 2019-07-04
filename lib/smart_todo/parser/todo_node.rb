# frozen_string_literal: true

module SmartTodo
  module Parser
    class TodoNode
      DEFAULT_RUBY_INDENTATION = 2

      attr_reader :metadata

      def initialize(todo)
        @metadata = MetadataParser.new(todo.gsub(/^#\s+@smart_todo/, '')).parse
        @comments = []
        @start = todo.match(/^#(\s+)/)[1].size
      end

      def comment
        @comments.join
      end

      def <<(comment)
        @comments << comment.gsub(/^#(\s+)/, '')
      end

      def indented_comment?(comment)
        comment.match(/^#(\s+)/)[1].size - @start == DEFAULT_RUBY_INDENTATION
      end
    end
  end
end
