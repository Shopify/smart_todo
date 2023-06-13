# frozen_string_literal: true

require "smart_todo/version"
require "smart_todo/events"

module SmartTodo
  autoload :SlackClient,              "smart_todo/slack_client"
  autoload :CLI,                      "smart_todo/cli"

  module Parser
    autoload :CommentParser,          "smart_todo/parser/comment_parser"
    autoload :TodoNode,               "smart_todo/parser/todo_node"
    autoload :MetadataParser,         "smart_todo/parser/metadata_parser"
  end

  module Events
    autoload :Date,                   "smart_todo/events/date"
    autoload :GemBump,                "smart_todo/events/gem_bump"
    autoload :GemRelease,             "smart_todo/events/gem_release"
    autoload :IssueClose,             "smart_todo/events/issue_close"
    autoload :RubyVersion,            "smart_todo/events/ruby_version"
  end

  module Dispatchers
    autoload :Base,                   "smart_todo/dispatchers/base"
    autoload :Slack,                  "smart_todo/dispatchers/slack"
    autoload :Output,                 "smart_todo/dispatchers/output"
  end
end
