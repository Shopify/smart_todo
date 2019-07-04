# frozen_string_literal: true

require 'ripper'
require_relative 'ast_node'

module SmartTodo
  module Parser
    class MetadataParser < Ripper
      def on_stmts_new
        ASTNode.new
      end

      def on_stmts_add(_list, values)
        values
      end

      def on_binary(lhs, operator, rhs)
        node = if lhs.is_a?(TodoTriggerNode)
          lhs << rhs
        else
          TodoTriggerNode.new([lhs, rhs])
        end

        rhs.assignee_method = true if operator == :>

        node
      end

      def on_method_add_arg(method_name, arguments)
        MethodNode.new(method_name, arguments)
      end

      def on_args_add_block(list, _block)
        list
      end

      def on_string_add(_, string)
        string
      end

      def on_args_add(list, value)
        list << value
      end

      def on_args_new
        ArgumentNode.new
      end
    end
  end
end
