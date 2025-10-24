# frozen_string_literal: true

require "smart_todo"
require "parser"

module RuboCop
  module Cop
    module SmartTodo
      # A RuboCop cop to enforce proper formatting of SmartTodo comments.
      # SmartTodo comments must have their description on separate lines, indented by 2 spaces.
      #
      # Bad:
      #   # TODO(on: date('2024-03-29'), to: 'john@example.com'): Remove this
      #   # TODO(on: date('2024-03-29'), to: 'john@example.com') Remove this
      #   # TODO(on: date('2024-03-29'), to: 'john@example.com')
      #   # Remove this (not indented)
      #
      # Good:
      #   # TODO(on: date('2024-03-29'), to: 'john@example.com')
      #   #   Remove this (indented by 2 extra spaces)
      #
      class SmartTodoCommentFormatCop < Base
        extend AutoCorrector

        MSG_INLINE = "SmartTodo comment must not be on the same line as the TODO. " \
          "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
        MSG_INDENT = "SmartTodo continuation line must be indented by 2 spaces. " \
          "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"

        SMART_TODO_PATTERN = /\A\s*#\s*(TODO|FIXME|OPTIMIZE)\(on:/
        INLINE_TEXT_PATTERN = /\A(\s*#\s*(?:TODO|FIXME|OPTIMIZE)\(.+\))\s*:?\s+(.+)/

        def on_new_investigation
          processed_source.comments.each_with_index do |comment, index|
            next unless smart_todo_comment?(comment)

            check_inline_text(comment)
            check_continuation_indent(comment, processed_source.comments[index + 1])
          end
        end

        private

        def smart_todo_comment?(comment)
          comment.text.match?(SMART_TODO_PATTERN)
        end

        def check_inline_text(comment)
          match = comment.text.match(INLINE_TEXT_PATTERN)
          return unless match

          add_offense(comment.location.expression, message: MSG_INLINE) do |corrector|
            todo_part = match[1]
            text_part = match[2]
            indentation = " " * comment.location.column

            corrected = "#{todo_part}\n#{indentation}#   #{text_part}"
            corrector.replace(comment.location.expression, corrected)
          end
        end

        def check_continuation_indent(comment, next_comment)
          return unless next_comment
          return unless next_comment.location.line == comment.location.line + 1
          return if smart_todo_comment?(next_comment)
          return if empty_comment?(next_comment)
          return if properly_indented?(next_comment)

          add_offense(next_comment.location.expression, message: MSG_INDENT) do |corrector|
            corrected = fix_indentation(next_comment.text)
            corrector.replace(next_comment.location.expression, corrected)
          end
        end

        def empty_comment?(comment)
          comment.text.match?(/\A\s*#\s*\z/)
        end

        def properly_indented?(comment)
          # A properly indented continuation has exactly 2 spaces after the #
          comment.text.match?(/\A\s*#   \S/)
        end

        def fix_indentation(text)
          # Extract leading whitespace and content
          match = text.match(/\A(\s*)#\s*(\S.*)\z/)
          return text unless match

          leading_space = match[1]
          content = match[2]
          "#{leading_space}#   #{content}"
        end
      end
    end
  end
end
