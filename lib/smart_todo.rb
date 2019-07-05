# frozen_string_literal: true

require "smart_todo/version"
require "smart_todo/events"

module SmartTodo
  autoload :SlackClient,              'smart_todo/slack_client'
  autoload :CLI,                      'smart_todo/cli'
  autoload :Dispatcher,               'smart_todo/dispatcher'

  module Parser
    autoload :CommentParser,          'smart_todo/parser/comment_parser'
    autoload :TodoNode,               'smart_todo/parser/todo_node'
    autoload :ASTNode,                'smart_todo/parser/ast_node'
    autoload :MetadataParser,         'smart_todo/parser/metadata_parser'
  end

  module Events
    autoload :Date,                   'smart_todo/events/date'
  end
end
