# frozen_string_literal: true

module SmartTodo
  class Todo
    attr_reader :filepath, :comment, :indent
    attr_reader :events, :assignees, :errors
    attr_accessor :context

    # Events that already contain issue/PR context and therefore
    # should not have additional context applied
    EVENTS_WITH_IMPLICIT_CONTEXT = [:issue_close, :pull_request_close].freeze

    class << self
      # Check if an event is eligible to have context information applied.
      # Events like issue_close and pull_request_close already reference
      # specific issues/PRs and shouldn't have additional context.
      #
      # @param event_name [Symbol] the name of the event method
      # @return [Boolean] true if the event can use context, false otherwise
      def event_can_use_context?(event_name)
        !EVENTS_WITH_IMPLICIT_CONTEXT.include?(event_name.to_sym)
      end
    end

    def initialize(source, filepath = "-e")
      @filepath = filepath
      @comment = +""
      @indent = source[/^#(\s+)/, 1].length

      @events = []
      @assignees = []
      @context = nil
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
          when :context
            value = visit(element.value)

            unless value.is_a?(String)
              metadata.errors << "Incorrect `:context` format: expected string value"
              next
            end

            unless value =~ %r{^([^/]+)/([^#]+)#(\d+)$}
              metadata.errors << "Incorrect `:context` format: expected \"org/repo#issue_number\""
              next
            end

            org = ::Regexp.last_match(1)
            repo = ::Regexp.last_match(2)
            issue_number = ::Regexp.last_match(3)

            if org.empty? || repo.empty?
              metadata.errors << "Incorrect `:context` format: org and repo cannot be empty"
            else
              metadata.context = CallNode.new(:issue, [org, repo, issue_number], element.value.location)
            end
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
