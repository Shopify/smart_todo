# frozen_string_literal: true

module SmartTodo
  module Parser
    class ASTNode < Array
    end

    class ArgumentNode < ASTNode
    end

    class MethodNode < ASTNode
      attr_reader :method_name
      attr_accessor :assignee_method

      def initialize(method_name, arguments, _opts = {})
        super(arguments)

        @method_name = method_name
        @assignee_method = false
      end

      alias_method :arguments, :entries
    end

    class TodoTriggerNode < ASTNode
      def events
        select { |entry| !entry.assignee_method }
      end

      def assignee
        find(&:assignee_method)
      end
    end
  end
end
