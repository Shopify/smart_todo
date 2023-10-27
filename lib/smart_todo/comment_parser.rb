# frozen_string_literal: true

module SmartTodo
  class CommentParser
    attr_reader :todos

    def initialize
      @todos = []
    end

    def parse(source, filepath = "-e")
      parse_comments(Prism.parse_comments(source), filepath)
    end

    def parse_file(filepath)
      parse_comments(Prism.parse_file_comments(filepath), filepath)
    end

    class << self
      def parse(source)
        parser = new
        parser.parse(source)
        parser.todos
      end
    end

    private

    def parse_comments(comments, filepath)
      current_todo = nil

      comments.each do |comment|
        next unless comment.is_a?(Prism::InlineComment)

        source = comment.location.slice

        if source.match?(/^#\sTODO\(/)
          todos << current_todo if current_todo
          current_todo = Todo.new(source, filepath)
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
