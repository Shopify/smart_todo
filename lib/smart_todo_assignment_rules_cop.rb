# frozen_string_literal: true

require "smart_todo"

module RuboCop
  module Cop
    module SmartTodo
      # A RuboCop cop to enforce assignment rules for smart TODOs.
      # This cop ensures that all smart TODOs (those with events and assignees) include
      # all configured required assignees in their assignees list, helping teams enforce
      # TODO assignment policies.
      #
      # Configuration:
      #   SmartTodo/AssignmentRules:
      #     RequiredAssignees:
      #       - '#project-alerts'
      #       - '@team-lead'
      #
      # @example
      #   # bad - smart TODO without all required assignees
      #   # TODO(on: date('2024-03-29'), to: 'john@example.com')
      #   #   Do something
      #
      #   # good - smart TODO includes all required assignees
      #   # TODO(on: date('2024-03-29'), to: 'john@example.com', to: '#project-alerts', to: '@team-lead')
      #   #   Do something
      #
      # @see https://rubocop.readthedocs.io/en/latest/extensions/#loading-extensions
      class AssignmentRules < Base
        INVESTIGATED_TAGS = ::SmartTodo::CommentParser::SUPPORTED_TAGS +
          ::SmartTodo::CommentParser::SUPPORTED_TAGS.map(&:downcase)
        TODO_PATTERN = /^#\s@?(#{INVESTIGATED_TAGS.join("|")})\(/

        # @param processed_source [RuboCop::ProcessedSource]
        # @return [void]
        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless TODO_PATTERN.match?(comment.text)
            next unless smart_todo?(comment)

            missing_assignees = find_missing_assignees(comment)
            next if missing_assignees.empty?

            add_offense(comment, message: offense_message(missing_assignees))
          end
        end

        private

        # @return [Array<String>] The required assignees from configuration
        # @raise [RuntimeError] if RequiredAssignees is not configured or empty
        def required_assignees
          @required_assignees ||= begin
            assignees = cop_config["RequiredAssignees"]
            if assignees.nil? || assignees.empty?
              raise "RequiredAssignees must be set for SmartTodo/AssignmentRules"
            end
            assignees
          end
        end

        # @param comment [RuboCop::AST::Comment]
        # @return [true, false] Whether the comment is a smart TODO
        def smart_todo?(comment)
          metadata = ::SmartTodo::Todo.new(comment.text, line_number: comment.loc.line)

          metadata.events.any? &&
            metadata.events.all? { |event| event.is_a?(::SmartTodo::Todo::CallNode) } &&
            metadata.assignees.any?
        end

        # @param comment [RuboCop::AST::Comment]
        # @return [Array<String>] List of required assignees that are missing from the TODO
        def find_missing_assignees(comment)
          metadata = ::SmartTodo::Todo.new(comment.text, line_number: comment.loc.line)
          todo_assignees = metadata.assignees.to_a

          required_assignees.reject { |assignee| todo_assignees.include?(assignee) }
        end

        # @param missing_assignees [Array<String>]
        # @return [String] The offense message
        def offense_message(missing_assignees)
          if missing_assignees.size == 1
            "Smart TODO must include required assignee: #{missing_assignees.first}"
          else
            "Smart TODO must include required assignees: #{missing_assignees.join(", ")}"
          end
        end
      end
    end
  end
end
