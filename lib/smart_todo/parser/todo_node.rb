# frozen_string_literal: true

module SmartTodo
  module Parser
    class TodoNode
      attr_reader = :metadata

      def initialize(todo)
        # @metadata = TodoMetadata.new(todo)
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
        comment.match(/^#(\s+)/)[1].size - @start == 2
      end
    end
  end
end
