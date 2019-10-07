# frozen_string_literal: true

require 'ripper'

module SmartTodo
  module Parser
    # A MethodNode represent an event associated to a TODO.
    class MethodNode
      attr_reader :method_name, :arguments

      # @param method_name [Symbol]
      # @param arguments [Array<String>]
      def initialize(method_name, arguments)
        @arguments = arguments
        @method_name = method_name
      end
    end

    # This class is used to parse the ruby TODO() comment.
    class MetadataParser < Ripper
      # @param source [String] the actual Ruby code
      def self.parse(source)
        sexp = new(source).parse
        Visitor.new.tap { |v| v.process(sexp) }
      end

      # @return [Array] an Array of Array
      #   the first element from each inner array is a token
      def on_stmts_add(_, data)
        data
      end

      # @param method [String] the name of the method
      #   when the parser hits one.
      # @param args [Array]
      # @return [Array, MethodNode]
      def on_method_add_arg(method, args)
        if method == 'TODO'
          args
        else
          MethodNode.new(method, args)
        end
      end

      # @param list [nil, Array]
      # @param arg [String]
      # @return [Array]
      def on_args_add(list, arg)
        Array(list) << arg
      end

      # @param string_content [String]
      # @return [String]
      def on_string_add(_, string_content)
        string_content
      end

      # @param key [String]
      # @param value [String, Integer, MethodNode]
      def on_assoc_new(key, value)
        key.tr!(':', '')

        case key
        when 'on'
          [:on_todo_event, value]
        when 'to'
          [:on_todo_assignee, value]
        else
          [:unknown, value]
        end
      end

      # @param data [Hash]
      # @return [Hash]
      def on_bare_assoc_hash(data)
        data
      end
    end

    class Visitor
      attr_reader :events, :assignee

      def initialize
        @events = []
      end

      # Iterate over each tokens returned from the parser and call
      # the corresponding method
      #
      # @param sexp [Array]
      # @return [void]
      def process(sexp)
        return unless sexp

        if sexp[0].is_a?(Array)
          sexp.each { |node| process(node) }
        else
          method, *args = sexp
          send(method, *args) if method.is_a?(Symbol) && respond_to?(method)
        end
      end

      # @param method_node [MethodNode]
      # @return [void]
      def on_todo_event(method_node)
        return unless method_node.is_a?(MethodNode)

        events << method_node
      end

      # @param assignee [String]
      # @return [void]
      def on_todo_assignee(assignee)
        @assignee = assignee
      end
    end
  end
end
