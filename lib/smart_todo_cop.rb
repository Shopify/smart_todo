# frozen_string_literal: true

require "smart_todo"
require "date"

module RuboCop
  module Cop
    module SmartTodo
      # A RuboCop used to restrict the usage of regular TODO comments in code.
      # This Cop does not run by default. It should be added to the RuboCop host's configuration file.
      #
      # @see https://rubocop.readthedocs.io/en/latest/extensions/#loading-extensions
      class SmartTodoCop < Base
        HELP = "For more info please look at https://github.com/Shopify/smart_todo/wiki/Syntax"
        MSG = "Don't write regular TODO comments. Write SmartTodo compatible syntax comments. #{HELP}"

        # @param processed_source [RuboCop::ProcessedSource]
        # @return [void]
        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless /^#\sTODO/.match?(comment.text)

            metadata = metadata(comment.text)

            if metadata.errors.any?
              add_offense(comment, message: "Invalid TODO format: #{metadata.errors.join(", ")}. #{HELP}")
            elsif !smart_todo?(metadata)
              add_offense(comment)
            elsif (methods = invalid_event_methods(metadata.events)).any?
              add_offense(comment, message: "Invalid event method(s): #{methods.join(", ")}. #{HELP}")
            elsif invalid_assignees(metadata.assignees).any?
              add_offense(comment, message: "Invalid event assignee. This method only accepts strings. #{HELP}")
            elsif (invalid_dates = invalid_dates(metadata.events)).any?
              add_offense(comment, message: "Invalid date format: #{invalid_dates.join(", ")}. #{HELP}")
            elsif (invalid_issue_close = invalid_issue_close_events(metadata.events)).any?
              add_offense(comment, message: "#{invalid_issue_close.join(", ")}. #{HELP}")
            elsif (invalid_pull_request_close = invalid_pull_request_close_events(metadata.events)).any?
              add_offense(comment, message: "#{invalid_pull_request_close.join(", ")}. #{HELP}")
            elsif (invalid_gem_release = invalid_gem_release_events(metadata.events)).any?
              add_offense(comment, message: "#{invalid_gem_release.join(", ")}. #{HELP}")
            end
          end
        end

        private

        # @param comment [String]
        # @return [SmartTodo::Parser::Visitor]
        def metadata(comment)
          ::SmartTodo::Todo.new(comment)
        end

        # @param metadata [SmartTodo::Parser::Visitor]
        # @return [true, false]
        def smart_todo?(metadata)
          metadata.events.any? &&
            metadata.events.all? { |event| event.is_a?(::SmartTodo::Todo::CallNode) } &&
            metadata.assignees.any?
        end

        # @param metadata [Array<SmartTodo::Parser::MethodNode>]
        # @return [Array<String>]
        def invalid_event_methods(events)
          events.map(&:method_name).reject { |method| ::SmartTodo::Events.method_defined?(method) }
        end

        # @param assignees [Array]
        # @return [Array]
        def invalid_assignees(assignees)
          assignees.reject { |assignee| assignee.is_a?(String) }
        end

        # @param events [Array<SmartTodo::Todo::CallNode>]
        # @return [Array<String>]
        def invalid_dates(events)
          events.select { |event| event.method_name == :date }
            .map { |event| validate_date(event.arguments.first) }
            .compact
        end

        # @param date_str [String]
        # @return [String, nil] Returns error message if date is invalid, nil if valid
        def validate_date(date_str)
          Date.parse(date_str)
          nil
        rescue ArgumentError, TypeError
          date_str
        end

        # @param events [Array<SmartTodo::Todo::CallNode>]
        # @return [Array<String>]
        def invalid_issue_close_events(events)
          events.select { |event| event.method_name == :issue_close }
            .map { |event| validate_issue_close_args(event.arguments) }
            .compact
        end

        # @param events [Array<SmartTodo::Todo::CallNode>]
        # @return [Array<String>]
        def invalid_pull_request_close_events(events)
          events.select { |event| event.method_name == :pull_request_close }
            .map { |event| validate_pull_request_close_args(event.arguments) }
            .compact
        end

        # @param events [Array<SmartTodo::Todo::CallNode>]
        # @return [Array<String>]
        def invalid_gem_release_events(events)
          events.select { |event| event.method_name == :gem_release }
            .map { |event| validate_gem_release_args(event.arguments) }
            .compact
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_gem_release_args(args)
          if args.empty?
            "Invalid gem_release event: Expected at least 1 argument (gem_name), got 0"
          elsif !args[0].is_a?(String)
            "Invalid gem_release event: First argument (gem_name) must be a string"
          elsif args.size > 1 && !args[1..].all? { |arg| arg.is_a?(String) }
            "Invalid gem_release event: Version requirements must be strings"
          end
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_pull_request_close_args(args)
          if args.size != 3
            "Invalid pull_request_close event: Expected 3 arguments (organization, repo, pr_number), got #{args.size}"
          elsif !args.all? { |arg| arg.is_a?(String) }
            "Invalid pull_request_close event: Arguments must be strings"
          end
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_issue_close_args(args)
          if args.size != 3
            "Invalid issue_close event: Expected 3 arguments (organization, repo, issue_number), got #{args.size}"
          elsif !args.all? { |arg| arg.is_a?(String) }
            "Invalid issue_close event: Arguments must be strings"
          end
        end
      end
    end
  end
end
