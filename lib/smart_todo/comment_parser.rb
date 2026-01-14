# frozen_string_literal: true

module SmartTodo
  class CommentParser
    SUPPORTED_TAGS = ["TODO", "FIXME", "OPTIMIZE"].freeze
    TAG_PATTERN = /^#\s(#{SUPPORTED_TAGS.join("|")})\(/

    attr_reader :todos

    def initialize
      @todos = []
    end

    if Prism.respond_to?(:parse_comments)
      def parse(source, filepath = "-e")
        parse_comments(Prism.parse_comments(source), filepath)
      end

      def parse_file(filepath)
        parse_comments(Prism.parse_file_comments(filepath), filepath)
      end
    else
      def parse(source, filepath = "-e")
        parse_comments(Prism.parse(source, filepath).comments, filepath)
      end

      def parse_file(filepath)
        parse_comments(Prism.parse_file(filepath).comments, filepath)
      end
    end

    class << self
      def parse(source)
        parser = new
        parser.parse(source)
        parser.todos
      end
    end

    private

    if defined?(Prism::InlineComment)
      def inline?(comment)
        comment.is_a?(Prism::InlineComment)
      end
    else
      def inline?(comment)
        comment.type == :inline
      end
    end

    def parse_comments(comments, filepath)
      current_todo = nil

      comments.each do |comment|
        next unless inline?(comment)

        source = comment.location.slice

        if source.match?(TAG_PATTERN)
          todos << current_todo if current_todo
          line_number = comment.location.start_line
          current_todo = Todo.new(source, filepath, line_number)
        elsif current_todo && (indent = source[/^#(\s*)/, 1].length) && (indent - current_todo.indent == 2)
          current_todo << "#{source[(indent + 1)..]}\n"
        else
          todos << current_todo if current_todo
          current_todo = nil
        end
      end

      todos << current_todo if current_todo
    end
  end
end
