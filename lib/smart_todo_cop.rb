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

        EVENTS = [
          :issue_close,
          :pull_request_close,
          :gem_release,
          :gem_bump,
          :ruby_version,
        ].freeze

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
            elsif (invalid_event = validate_events(metadata.events)).any?
              add_offense(comment, message: "#{invalid_event.join(", ")}. #{HELP}")
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
        def validate_events(events)
          EVENTS.flat_map do |event_type|
            events.select { |event| event.method_name == event_type }
              .map { |event| send(validate_method(event_type), event.arguments) }
              .compact
          end
        end

        def validate_method(event_type)
          "validate_#{event_type}_args"
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_issue_close_args(args)
          validate_fixed_arity_args(args, 3, "issue_close", ["organization", "repo", "issue_number"])
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_pull_request_close_args(args)
          validate_fixed_arity_args(args, 3, "pull_request_close", ["organization", "repo", "pr_number"])
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_gem_release_args(args)
          validate_gem_args(args, "gem_release")
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_gem_bump_args(args)
          validate_gem_args(args, "gem_bump")
        end

        # @param args [Array]
        # @return [String, nil] Returns error message if arguments are invalid, nil if valid
        def validate_ruby_version_args(args)
          if args.empty?
            "Invalid ruby_version event: Expected at least 1 argument (version requirement), got 0"
          elsif !args.all? { |arg| arg.is_a?(String) }
            "Invalid ruby_version event: Version requirements must be strings"
          end
        end

        # Helper method for validating fixed arity events
        def validate_fixed_arity_args(args, expected_count, event_name, arg_names)
          if args.size != expected_count
            message = "Invalid #{event_name} event: Expected #{expected_count} arguments "
            message += "(#{arg_names.join(", ")}), got #{args.size}"
            message
          elsif !args.all? { |arg| arg.is_a?(String) }
            "Invalid #{event_name} event: Arguments must be strings"
          end
        end

        # Helper method for validating gem-related events
        def validate_gem_args(args, event_name)
          if args.empty?
            "Invalid #{event_name} event: Expected at least 1 argument (gem_name), got 0"
          elsif !args[0].is_a?(String)
            "Invalid #{event_name} event: First argument (gem_name) must be a string"
          elsif args.size > 1 && !args[1..].all? { |arg| arg.is_a?(String) }
            "Invalid #{event_name} event: Version requirements must be strings"
          end
        end
      end
    end
  end
end
