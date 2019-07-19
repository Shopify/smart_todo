# frozen_string_literal: true

module SmartTodo
  module Parser
    # Represents a SmartTodo which includes the associated events
    # as well as the assignee.
    class TodoNode
      DEFAULT_RUBY_INDENTATION = 2

      attr_reader :metadata

      # @param todo [String] the actual Ruby comment
      def initialize(todo)
        @metadata = MetadataParser.parse(todo.gsub(/^#/, ''))
        @comments = []
        @start = todo.match(/^#(\s+)/)[1].size
      end

      # Return the associated comment for this TODO
      #
      # @return [String]
      def comment
        @comments.join
      end

      # @param comment [String]
      # @return [void]
      def <<(comment)
        @comments << comment.gsub(/^#(\s+)/, '')
      end

      # Check if the +comment+ is indented two spaces below the
      # TODO declaration. If yes the comment is considered to be part
      # of the TODO itself. Otherwise it's just a regular comment.
      #
      # @param comment [String]
      # @return [true, false]
      def indented_comment?(comment)
        comment.match(/^#(\s+)/)[1].size - @start == DEFAULT_RUBY_INDENTATION
      end
    end
  end
end
