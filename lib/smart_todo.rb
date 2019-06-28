# frozen_string_literal: true

require "smart_todo/version"

module SmartTodo
  module Parser
    autoload :CommentParser,          'smart_todo/parser/comment_parser'
    autoload :TodoNode,               'smart_todo/parser/todo_node'
    autoload :TodoMetadata,           'smart_todo/parser/todo_metadata'
  end
end
