# frozen_string_literal: true

require "ripper"

module SmartTodo
  module Parser
    # This class is used to parse Ruby code and will stop each time
    # a Ruby comment is encountered. It will detect if a TODO comment
    # is a Smart Todo and will gather the comments associated to the TODO.
    class CommentParser < Ripper::Filter
      def initialize(*)
        super
        @node = nil
      end

      # @param comment [String] the actual Ruby comment
      # @param data [Array<TodoNode>]
      # @return [Array<TodoNode>]
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

      # @param init [Array]
      # @return [Array<TodoNode>]
      def parse(init = [])
        super(init)

        init.tap { append_existing_node(init) }
      end

      private

      # @param comment [String] the actual Ruby comment
      # @return [nil, Integer]
      def todo_metadata?(comment)
        /^#\sTODO\(/ =~ comment
      end

      # Check if the comment is associated with the Smart Todo
      # @param comment [String] the actual Ruby comment
      # @return [true, false]
      #
      # @example When a comment is associated to a SmartTodo
      #   TODO(on_date(...), to: '...')
      #     This is an associated comment
      #
      # @example When a comment is not associated to a SmartTodo
      #   TODO(on_date(...), to: '...')
      #   This is an associated comment (Note the indentation)
      def todo_comment?(comment)
        @node&.indented_comment?(comment)
      end

      # @param data [Array<TodoNode>]
      # @return [Array<TodoNode>]
      def append_existing_node(data)
        data << @node if @node
      end
    end
  end
end
