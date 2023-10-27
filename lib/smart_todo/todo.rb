# frozen_string_literal: true

module SmartTodo
  class Todo
    attr_reader :filepath, :comment, :indent
    attr_reader :events, :assignees, :errors

    def initialize(source, filepath = "-e")
      @filepath = filepath
      @comment = +""
      @indent = source[/^#(\s+)/, 1].length

      @events = []
      @assignees = []
      @errors = []

      parse(source[(indent + 1)..])
    end

    def <<(source)
      comment << source
    end

    class CallNode
      attr_reader :method_name, :arguments, :location

      def initialize(method_name, arguments, location)
        @arguments = arguments
        @method_name = method_name
        @location = location
      end
    end

    class Compiler < Prism::Compiler
      attr_reader :metadata

      def initialize(metadata)
        super()
        @metadata = metadata
      end

      def visit_call_node(node)
        CallNode.new(node.name, visit_all(node.arguments&.arguments || []), node.location)
      end

      def visit_integer_node(node)
        node.value
      end

      def visit_keyword_hash_node(node)
        node.elements.each do |element|
          next unless (key = element.key).is_a?(Prism::SymbolNode)

          case key.unescaped.to_sym
          when :on
            value = visit(element.value)

            if value.is_a?(CallNode)
              if value.arguments.all? { |arg| arg.is_a?(Integer) || arg.is_a?(String) }
                metadata.events << value
              else
                metadata.errors << "Incorrect `:on` event format: #{value.location.slice}"
              end
            else
              metadata.errors << "Incorrect `:on` event format: #{value.inspect}"
            end
          when :to
            metadata.assignees << visit(element.value)
          end
        end
      end

      def visit_string_node(node)
        node.unescaped
      end
    end

    private

    def parse(source)
      Prism.parse(source).value.statements.body.first.accept(Compiler.new(self))
    end
  end
end
