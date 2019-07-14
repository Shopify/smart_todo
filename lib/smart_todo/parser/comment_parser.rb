# frozen_string_literal: true

require 'ripper'

module SmartTodo
  module Parser
    class CommentParser < Ripper::Filter
      def initialize(*)
        super
        @node = nil
      end

      def on_comment(comment, data)
        if todo_metadata?(comment)
          append_existing_node(data)
          @node = TodoNode.new(comment)
        elsif todo_comment?(comment)
          @node << comment
        else
          append_existing_node(data)
          @node = nil
        end

        data
      end

      def parse(init = [])
        super(init)

        init.tap { append_existing_node(init) }
      end

      private

      def todo_metadata?(comment)
        comment.start_with?(/#\sTODO\(/)
      end

      def todo_comment?(comment)
        @node&.indented_comment?(comment)
      end

      def append_existing_node(data)
        data << @node if @node
      end
    end
  end
end
