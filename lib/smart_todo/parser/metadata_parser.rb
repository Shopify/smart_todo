# frozen_string_literal: true

require 'ripper'

module SmartTodo
  module Parser
    class MethodNode
      attr_reader :method_name, :arguments

      def initialize(method_name, arguments)
        @arguments = arguments
        @method_name = method_name
      end
    end

    class MetadataParser < Ripper
      def self.parse(source)
        sexp = new(source).parse
        Visitor.new.tap { |v| v.process(sexp) }
      end

      def on_stmts_add(_, data)
        data
      end

      def on_method_add_arg(method, args)
        if method == 'TODO'
          args
        else
          MethodNode.new(method, args)
        end
      end

      def on_args_add(list, arg)
        Array(list) << arg
      end

      def on_string_add(_, string_content)
        string_content
      end

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

      def on_bare_assoc_hash(data)
        data
      end
    end

    class Visitor
      attr_reader :events, :assignee

      def initialize
        @events = []
      end

      def process(sexp)
        return unless sexp

        if sexp[0].is_a?(Array)
          sexp.each { |node| process(node) }
        else
          method, *args = sexp
          send(method, *args) if method.is_a?(Symbol) && respond_to?(method)
        end
      end

      def on_todo_event(method_node)
        events << method_node
      end

      def on_todo_assignee(assignee)
        @assignee = assignee
      end
    end
  end
end
